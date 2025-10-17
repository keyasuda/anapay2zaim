# Zaim API Authentication Scripts

This directory contains scripts for Zaim API authentication and setup.

## Scripts

### 1. Token Acquisition Script

`token_acquirer.rb` - This script handles the OAuth 1.0a flow to acquire access tokens from Zaim.

**Usage:**
```bash
ruby auth/token_acquirer.rb
```

This will:
1. Get a request token from Zaim
2. Provide an authorization URL
3. Prompt for the oauth_verifier after you authorize the application
4. Exchange the request token for access tokens
5. Save the tokens to `zaim_tokens.json`

### 2. Genre Retrieval Script

`genre_retriever.rb` - This script retrieves the list of genres from Zaim and saves them to a local file.

**Usage:**
```bash
ruby auth/genre_retriever.rb
```

This will:
1. Load access tokens from `zaim_tokens.json`
2. Make an authenticated API call to retrieve genres
3. Save the genres to `zaim_genres.json`

## Prerequisites

Before running these scripts, make sure you have:

1. Zaim API credentials (Consumer ID and Consumer Secret)
2. Set up your `.env` file with the following variables:
   ```
   ZAIM_CONSUMER_ID=your_consumer_id
   ZAIM_CONSUMER_SECRET=your_consumer_secret
   ```

## Notes

- The token acquisition script needs to be run only once to get the access tokens
- Keep `zaim_tokens.json` secure as it contains sensitive credentials
- The genre retrieval script can be run whenever you need to refresh the genre list