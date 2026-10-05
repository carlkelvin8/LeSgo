<?php

namespace Tests\Unit;

use App\Services\SafePublicStoragePath;
use Tests\TestCase;

class SafePublicStoragePathTest extends TestCase
{
    public function test_storage_keys_reject_encoded_and_plain_traversal(): void
    {
        self::assertNull(SafePublicStoragePath::normalizeKey('../.env'));
        self::assertNull(SafePublicStoragePath::normalizeKey('avatars/%2e%2e/%2e%2e/.env'));
        self::assertNull(SafePublicStoragePath::normalizeKey('avatars\\..\\.env'));
        self::assertSame('avatars/customer/photo.jpg', SafePublicStoragePath::normalizeKey('avatars/customer/photo.jpg'));
    }

    public function test_local_files_must_resolve_under_public_storage(): void
    {
        self::assertNull(SafePublicStoragePath::resolveLocalFile('../.env'));
    }
}
