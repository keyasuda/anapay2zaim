# Email Fetching Implementation

## Overview
The email fetching functionality retrieves ANA Pay notification emails using the IMAP4 protocol. The implementation is contained in `lib/email_fetcher.rb`.

## Key Components

### EmailFetcher Class
- Connects to the email server using IMAP
- Searches for ANA Pay related emails from the last 7 days
- Extracts relevant transaction information from each email
- Implements message-id based deduplication to prevent reprocessing

### Configuration
- Uses environment variables loaded via dotenv
- Supports customizable IMAP settings (host, port, SSL)
- Requires email credentials for authentication

### Search Criteria
- Subject contains 'ANA Pay'
- Emails from the last 7 days
- Sender domain related to ANA Pay (ana.co.jp or ana-pay)

## Processing Flow
1. Connect to the IMAP server using provided credentials
2. Select the INBOX folder
3. Search for emails matching ANA Pay criteria
4. For each matching email, extract:
   - Message ID (for deduplication)
   - Subject
   - Date
   - Parsed transaction information
5. Return array of processed emails

## Security
- Credentials are loaded from environment variables
- IMAP connections use SSL by default
- Raw email content is processed to extract only necessary information

## Error Handling
- Checks for required configuration before attempting connection
- Provides clear error messages for missing configuration
- Uses proper exception handling patterns