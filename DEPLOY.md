

## Step 1: Install Fly CLI

https://fly.io/docs/getting-started/installing-flyctl/

```
flyctl auth login
```

## Step 2: Deploy

```
flyctl deploy
```

## Step 3: Update Secret

```
flyctl secrets import < .env_prod
```

## Step 4: CLI

```
flyctl console
```