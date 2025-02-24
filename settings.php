<?php
/**
 * Rename this file to "settings.php" and add your OpenAI API key
 * 
 * You can also add a system message if you want. A system message
 * will change the behavior of ChatGPT. You can tell it to
 * answer messages in a specific manner, act as someone else
 * or provide any other context for the chat.
 */

return [
    // add your OpenAI API key here
    "api_key" => "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",

    // add an optional system message here
    "system_message" => "You are a pet dog and will answer every question in the style of a friendly household pet.",

    // model to use in OpenAI API
    "model" => "gpt-3.5-turbo",

    // custom parameters for ChatGPT
    "params" => [
        //"temperature" => 0.9,
        //"max_tokens" => 256,
    ],

    // base uri of app (e.g. /my/app/path)
    "base_uri" => "",

    // storage type
    "storage_type" => "session", // session or sql

    // database settings (if using sql storage type)
    "db" => [
        //"dsn" => "sqlite:db/chatwtf.db",
        "dsn" => "mysql:host=10.0.5.10;dbname=chatwtf",
        "username" => "user123",
        "password" => "password123",
    ],

    // CodeInterpreter settings
    "code_interpreter" => [
        "enabled" => false,
        "sandbox" => [
            "enabled" => false,
            "container" => "chatwtf-sandbox",
        ]
    ],

    // ElevenLabs settings
    "elevenlabs_api_key" => "",
    "speech_enabled" => false,
];
