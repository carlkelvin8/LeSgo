<?php

namespace App\Services;

/**
 * Masks common profanity and slurs (English and Filipino) in chat messages
 * before they are stored or broadcast. Part of the objectionable-content
 * filtering required by App Store Guideline 1.2.
 */
class ChatContentFilter
{
    private const BLOCKED_WORDS = [
        // English
        'fuck', 'fucking', 'fucker', 'motherfucker', 'shit', 'bitch', 'bastard',
        'asshole', 'cunt', 'dick', 'pussy', 'whore', 'slut', 'faggot', 'nigger', 'retard',
        // Filipino
        'putangina', 'putang ina', 'tangina', 'tang ina', 'puta', 'gago', 'gaga',
        'ulol', 'tarantado', 'tarantada', 'pakyu', 'pakshet', 'kupal', 'bobo',
        'tanga', 'leche', 'punyeta', 'hayop ka', 'pokpok', 'bwisit', 'kantot', 'tite', 'puke',
    ];

    public function clean(string $text): string
    {
        foreach (self::BLOCKED_WORDS as $word) {
            $pattern = '/\b' . str_replace(' ', '\s*', preg_quote($word, '/')) . '\b/iu';
            $text = preg_replace_callback(
                $pattern,
                fn (array $m) => mb_substr($m[0], 0, 1) . str_repeat('*', max(mb_strlen($m[0]) - 1, 1)),
                $text
            );
        }

        return $text;
    }
}
