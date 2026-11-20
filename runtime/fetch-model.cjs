const fs = require('node:fs');
const path = require('node:path');
const {
  S3Client,
  ListObjectsV2Command,
  GetObjectCommand,
} = require('@aws-sdk/client-s3');

const PART_SIZE = 16 * 1024 * 1024;
const CONCURRENCY = 16;

const bucket = process.env.MODEL_BUCKET;
const prefix = (
  process.env.MODEL_PREFIX ?? `models/${process.env.OLLAMA_MODEL}`
).replace(/\/+$/, '');
const dest = process.env.OLLAMA_MODELS;

const s3 = new S3Client({
  region: process.env.MODEL_BUCKET_REGION || process.env.AWS_REGION,
  followRegionRedirects: true,
});

async function listObjects() {
  const objects = [];
  let token;
  do {
    const res = await s3.send(
      new ListObjectsV2Command({
        Bucket: bucket,
        Prefix: `${prefix}/`,
        ContinuationToken: token,
      }),
    );
    for (const o of res.Contents ?? []) {
      if (!o.Key.endsWith('/')) objects.push({ key: o.Key, size: o.Size });
    }
    token = res.IsTruncated ? res.NextContinuationToken : undefined;
  } while (token);
  return objects;
}

async function runPool(tasks, limit) {
  let next = 0;
  const worker = async () => {
    while (next < tasks.length) await tasks[next++]();
  };
  await Promise.all(Array.from({ length: limit }, worker));
}

async function download({ key, size }) {
  const target = path.join(dest, key.slice(prefix.length + 1));
  if (fs.existsSync(target) && fs.statSync(target).size === size) return 0;

  fs.mkdirSync(path.dirname(target), { recursive: true });
  const tmp = `${target}.part`;
  const fh = await fs.promises.open(tmp, 'w');
  try {
    const parts = [];
    for (let start = 0; start < size; start += PART_SIZE) {
      const end = Math.min(start + PART_SIZE, size) - 1;
      parts.push(async () => {
        const res = await s3.send(
          new GetObjectCommand({
            Bucket: bucket,
            Key: key,
            Range: `bytes=${start}-${end}`,
          }),
        );
        const buf = Buffer.from(await res.Body.transformToByteArray());
        await fh.write(buf, 0, buf.length, start);
      });
    }
    await runPool(parts, CONCURRENCY);
  } finally {
    await fh.close();
  }
  fs.renameSync(tmp, target);
  return size;
}

async function main() {
  if (!bucket || !dest) {
    throw new Error('MODEL_BUCKET and OLLAMA_MODELS must be set');
  }
  const started = Date.now();
  const objects = await listObjects();
  if (objects.length === 0) {
    throw new Error(`no model files under s3://${bucket}/${prefix}/`);
  }

  let bytes = 0;
  for (const o of objects) bytes += await download(o);

  const secs = (Date.now() - started) / 1000;
  console.log(
    `fetch-model: s3://${bucket}/${prefix}/ -> ${dest} ` +
      `${(bytes / 1e6).toFixed(0)}MB downloaded in ${secs.toFixed(1)}s`,
  );
}

main().catch((err) => {
  console.error(`fetch-model: ${err.stack ?? err}`);
  process.exit(1);
});
