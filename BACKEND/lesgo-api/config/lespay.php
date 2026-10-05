<?php

return [
    // 3% service fee on each LesPay wallet top-up (added to payment total).
    'top_up_fee_rate' => (float) env('LESPAY_TOP_UP_FEE_RATE', 0.03),

    // Default payment gateway: 'paymongo' or 'xendit'
    'default_gateway' => env('LESPAY_DEFAULT_GATEWAY', 'paymongo'),
];
