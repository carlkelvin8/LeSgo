<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    // =========
    // Twilio (SMS — global)
    // =========
    'twilio' => [
        'sid'   => env('TWILIO_SID'),
        'token' => env('TWILIO_AUTH_TOKEN'),
        'from'  => env('TWILIO_FROM'),
        'verify_service_sid' => env('TWILIO_VERIFY_SERVICE_SID', 'VA4f1d61a444da19e50980696c9a96d710'),
    ],

    // =========
    // Semaphore (SMS — PH fallback)
    // =========
    'semaphore' => [
        'api_key'     => env('SEMAPHORE_API_KEY'),
        'sender_name' => env('SEMAPHORE_SENDER_NAME', 'LESGO'),
    ],

    // =========
    // PayMongo (PH payment gateway — default)
    // =========
    'paymongo' => [
        'secret_key'            => env('PAYMONGO_SECRET_KEY'),
        'public_key'            => env('PAYMONGO_PUBLIC_KEY'),
        'webhook_secret'        => env('PAYMONGO_WEBHOOK_SECRET'),
        'success_url'           => env('PAYMONGO_SUCCESS_URL', 'lesgo://lespay/topup/success'),
        'failure_url'           => env('PAYMONGO_FAILURE_URL', 'lesgo://lespay/topup/failure'),
        // Source wallet/account for mission reward reimbursements & payouts
        'wallet_account_number' => env('PAYMONGO_WALLET_ACCOUNT_NUMBER', env('PAYMONGO_SOURCE_ACCOUNT_NUMBER', '')),
        'wallet_account_name'   => env('PAYMONGO_WALLET_ACCOUNT_NAME', env('PAYMONGO_SOURCE_ACCOUNT_NAME', 'LeSGo Platform')),
        'wallet_bic'            => env('PAYMONGO_WALLET_BIC', 'PAEYPHM2XXX'),
        'webhook_url'           => env('PAYMONGO_WEBHOOK_URL', env('APP_URL', '') . '/api/v1/webhooks/payments/paymongo'),
    ],

    // =========
    // Xendit (PH payment gateway — fallback)
    // =========
    'xendit' => [
        'secret_key'    => env('XENDIT_SECRET_KEY'),
        'public_key'    => env('XENDIT_PUBLIC_KEY'),
        'webhook_token' => env('XENDIT_WEBHOOK_TOKEN'), // X-CALLBACK-TOKEN from Xendit dashboard
        'success_url'   => env('XENDIT_SUCCESS_URL', 'https://app.lesgo.ph/payment/success'),
        'failure_url'   => env('XENDIT_FAILURE_URL', 'https://app.lesgo.ph/payment/failed'),
    ],

    // =========
    // GCash / Maya webhook secrets (direct integrations, if any)
    // =========
    'gcash' => [
        'webhook_secret' => env('GCASH_WEBHOOK_SECRET'),
    ],

    'maya' => [
        'webhook_secret' => env('MAYA_WEBHOOK_SECRET'),
    ],

    // =========
    // Google Maps API
    // =========
    'google_maps' => [
        'api_key' => env('GOOGLE_MAPS_API_KEY'),
    ],

    // =========
    // Google OAuth (Sign in with Google)
    // =========
    'google' => [
        // OAuth client IDs are public identifiers embedded in the mobile app.
        // Keep the environment override for rotations and other deployments.
        'client_id' => env('GOOGLE_CLIENT_ID', '937689509907-v9sig2gpdnkvera15mv0n2ijc0usalbv.apps.googleusercontent.com'),
    ],

    // =========
    // Sign in with Apple (client ID is the iOS bundle identifier)
    // =========
    'apple' => [
        'client_id' => env('APPLE_CLIENT_ID', 'com.lesgo.app'),
        // Only needed to revoke Apple tokens when an account is deleted.
        // Leave unset to skip revocation (sign-in works without them).
        'team_id' => env('APPLE_TEAM_ID'),
        'key_id' => env('APPLE_KEY_ID'),
        'private_key' => env('APPLE_PRIVATE_KEY'),
    ],

    // =========
    // Firebase (mobile push — public client config)
    // =========
    'firebase' => [
        'project_id' => env('FIREBASE_PROJECT_ID'),
        'messaging_sender_id' => env('FIREBASE_MESSAGING_SENDER_ID'),
        'android_api_key' => env('FIREBASE_API_KEY_ANDROID'),
        'android_app_id' => env('FIREBASE_APP_ID_ANDROID'),
        'ios_api_key' => env('FIREBASE_API_KEY_IOS'),
        'ios_app_id' => env('FIREBASE_APP_ID_IOS'),
        'ios_bundle_id' => env('FIREBASE_IOS_BUNDLE_ID', 'com.lesgo.app'),
        'credentials' => env('FIREBASE_CREDENTIALS'),
    ],

];
