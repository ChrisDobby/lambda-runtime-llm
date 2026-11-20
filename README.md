# A look at Customer Managed Runtimes. Let's run an LLM...

Companion code for the blog post here

## Steps

### Ensure your AWS account number is available

```
export AWS_ACCOUNT_ID=<AWS account number>
```

### Create a new bucket and set the MODEL_BUCKET env var

```
export MODEL_BUCKET=<bucket name>
```

### Upload the llama model to the bucket

```
sh ./upload-model.sh llama3.2:1b
```

### Create the llama container image

```
sh ./deploy-container.sh Dockerfile.llama llama
```

### Create the Customer Managed Runtime

```
sh ./deploy-runtime.sh llama
```

Note the RUNTIME_ARN and RUNTIME_VERSION

### Create the Runtime Alias

```
sh ./deploy-runtime-alias.sh RUNTIME_VERSION
```

### Create the Lambda Function

```
sh ./deploy-test-function.sh RUNTIME_ARN
```

Invoking the Lambda will now call the `llama` LLM using the hardcoded prompt. Pass in a tenant id to force a cold start.

```
sh ./invoke-test-function.sh
```

### Upload the gemma model to the bucket

```
sh ./upload-model.sh gemma:2b
```

### Create the gemma container image

```
sh ./deploy-container.sh Dockerfile.gemma gemma
```

### Create a new Runtime Version

```
sh ./deploy-runtime.sh gemma
```

Note the RUNTIME_VERSION

### Update the Runtime Alias to the new version

```
sh ./deploy-runtime-alias.sh RUNTIME_VERSION
```

Now invoking the Lambda will call the `gemma` model instead

```
sh ./invoke-test-function.sh
```

### Roll the Runtime Alias back to the old version

```
sh ./deploy-runtime-alias.sh vllama
```

Now invoking the Lambda will call the `llama` model again

```
sh ./invoke-test-function.sh
```
