import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/responsive_utils.dart';

class RiderFaqsScreen extends StatefulWidget {
  const RiderFaqsScreen({super.key});

  @override
  State<RiderFaqsScreen> createState() => _RiderFaqsScreenState();
}

class _RiderFaqsScreenState extends State<RiderFaqsScreen> {
  List<dynamic> _faqs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final faqs = await ApiService.getFaqArticles();
      if (!mounted) return;
      setState(() {
        _faqs = faqs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.extractError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RiderApiScaffold(
      title: 'FAQs',
      loading: _loading,
      error: _error,
      onRetry: _load,
      child: ListView.builder(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          final faq = _faqs[index] as Map<String, dynamic>;
          return ExpansionTile(
            title: Text(
              faq['title']?.toString() ?? 'Question',
              style: const TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  faq['content']?.toString() ?? '',
                  style: const TextStyle(fontFamily: 'TT Fors'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class RiderOffersScreen extends StatefulWidget {
  const RiderOffersScreen({super.key});

  @override
  State<RiderOffersScreen> createState() => _RiderOffersScreenState();
}

class _RiderOffersScreenState extends State<RiderOffersScreen> {
  List<dynamic> _offers = [];
  bool _loading = true;
  String? _error;
  final Set<String> _claimingCodes = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final offers = await ApiService.getAvailableVouchers();
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.extractError(e);
        _loading = false;
      });
    }
  }

  Future<void> _claimOffer(Map<String, dynamic> offer) async {
    final code = offer['code']?.toString() ?? offer['voucher_code']?.toString();
    if (code == null || code.isEmpty) return;
    setState(() => _claimingCodes.add(code));
    try {
      await ApiService.claimVoucher(code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Claimed $code successfully')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.extractError(e))),
      );
    } finally {
      if (mounted) setState(() => _claimingCodes.remove(code));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RiderApiScaffold(
      title: 'Offers',
      loading: _loading,
      error: _error,
      onRetry: _load,
      child: ListView.builder(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        itemCount: _offers.length,
        itemBuilder: (context, index) {
          final offer = _offers[index] as Map<String, dynamic>;
          final code = offer['code']?.toString() ?? offer['voucher_code']?.toString() ?? '';
          final eligible = offer['eligible'] != false;
          final claiming = _claimingCodes.contains(code);
          return Card(
            child: ListTile(
              title: Text(
                offer['title']?.toString() ??
                    (code.isEmpty ? 'Offer' : code),
                style: const TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                offer['description']?.toString() ?? '',
                style: const TextStyle(fontFamily: 'TT Fors'),
              ),
              trailing: eligible
                  ? TextButton(
                      onPressed: claiming || code.isEmpty
                          ? null
                          : () => _claimOffer(offer),
                      child: claiming
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Claim'),
                    )
                  : const Text('Claimed', style: TextStyle(color: Colors.grey)),
            ),
          );
        },
      ),
    );
  }
}

class RiderLoyaltyScreen extends StatefulWidget {
  const RiderLoyaltyScreen({super.key});

  @override
  State<RiderLoyaltyScreen> createState() => _RiderLoyaltyScreenState();
}

class _RiderLoyaltyScreenState extends State<RiderLoyaltyScreen> {
  List<dynamic> _rewards = [];
  bool _loading = true;
  String? _error;
  int? _redeemingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rewards = await ApiService.getLoyaltyRewards();
      if (!mounted) return;
      setState(() {
        _rewards = rewards;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.extractError(e);
        _loading = false;
      });
    }
  }

  Future<void> _redeem(Map<String, dynamic> reward) async {
    final rewardId = (reward['id'] as num?)?.toInt();
    if (rewardId == null) return;
    setState(() => _redeemingId = rewardId);
    try {
      final result = await ApiService.redeemLoyaltyReward(rewardId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['reward_title']?.toString() ?? 'Reward redeemed',
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.extractError(e))),
      );
    } finally {
      if (mounted) setState(() => _redeemingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RiderApiScaffold(
      title: 'Loyalty Rewards',
      loading: _loading,
      error: _error,
      onRetry: _load,
      child: ListView.builder(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        itemCount: _rewards.length,
        itemBuilder: (context, index) {
          final reward = _rewards[index] as Map<String, dynamic>;
          final rewardId = (reward['id'] as num?)?.toInt();
          final available = reward['available'] == true;
          final redeeming = rewardId != null && _redeemingId == rewardId;
          return ListTile(
            tileColor: Colors.grey.shade50,
            title: Text(
              reward['title']?.toString() ?? reward['name']?.toString() ?? 'Reward',
              style: const TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${reward['points_cost'] ?? reward['points_required'] ?? 0} points',
              style: const TextStyle(fontFamily: 'TT Fors'),
            ),
            trailing: available
                ? TextButton(
                    onPressed: redeeming || rewardId == null
                        ? null
                        : () => _redeem(reward),
                    child: redeeming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Redeem'),
                  )
                : const Text('Locked', style: TextStyle(color: Colors.grey)),
          );
        },
      ),
    );
  }
}

class RiderReferralScreen extends StatefulWidget {
  const RiderReferralScreen({super.key});

  @override
  State<RiderReferralScreen> createState() => _RiderReferralScreenState();
}

class _RiderReferralScreenState extends State<RiderReferralScreen> {
  Map<String, dynamic> _dashboard = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dashboard = await ApiService.getReferralDashboard();
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.extractError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RiderApiScaffold(
      title: 'Referral Dashboard',
      loading: _loading,
      error: _error,
      onRetry: _load,
      child: ListView(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        children: [
          _StatTile('Referral Code', _dashboard['referral_code']?.toString() ?? '—'),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                final code = _dashboard['referral_code']?.toString();
                if (code == null || code.isEmpty) return;
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Referral code copied')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy code'),
            ),
          ),
          _StatTile('Invites Sent', '${_dashboard['invites_sent'] ?? 0}'),
          _StatTile('Friends Joined', '${_dashboard['friends_joined'] ?? 0}'),
          _StatTile('Points Earned', '${_dashboard['points_earned'] ?? 0}'),
        ],
      ),
    );
  }
}

class RiderSecurityScreen extends StatefulWidget {
  const RiderSecurityScreen({super.key});

  @override
  State<RiderSecurityScreen> createState() => _RiderSecurityScreenState();
}

class _RiderSecurityScreenState extends State<RiderSecurityScreen> {
  Map<String, dynamic> _dashboard = {};
  bool _loading = true;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dashboard = await ApiService.getSecurityDashboard();
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.extractError(e);
        _loading = false;
      });
    }
  }

  bool get _twoFaEnabled =>
      _dashboard['two_factor_enabled'] == true ||
      _dashboard['is_2fa_enabled'] == true;

  Future<void> _setup2fa() async {
    setState(() => _working = true);
    try {
      final setup = await ApiService.setup2fa();
      if (!mounted) return;
      final codeController = TextEditingController();
      final secret = setup['secret']?.toString() ?? '';
      final qrUrl = setup['qr_code_url']?.toString() ?? '';
      final verified = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable 2FA'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (secret.isNotEmpty) Text('Secret: $secret'),
                if (qrUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SelectableText(qrUrl, style: const TextStyle(fontSize: 11)),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Authenticator code',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Verify'),
            ),
          ],
        ),
      );
      if (verified == true && codeController.text.trim().length == 6) {
        await ApiService.verify2fa(codeController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('2FA enabled successfully')),
          );
        }
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.extractError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _disable2fa() async {
    setState(() => _working = true);
    try {
      await ApiService.disable2fa();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('2FA disabled')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.extractError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RiderApiScaffold(
      title: 'Security',
      loading: _loading,
      error: _error,
      onRetry: _load,
      child: ListView(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        children: [
          _StatTile('2FA Status', _twoFaEnabled ? 'Enabled' : 'Disabled'),
          _StatTile(
            'Biometric Devices',
            '${(_dashboard['biometric_devices'] as List?)?.length ?? _dashboard['biometrics_count'] ?? 0}',
          ),
          _StatTile(
            'Recent Login Events',
            '${(_dashboard['recent_logins'] as List?)?.length ?? 0}',
          ),
          const SizedBox(height: 16),
          if (_twoFaEnabled)
            OutlinedButton(
              onPressed: _working ? null : _disable2fa,
              child: _working
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Disable 2FA'),
            )
          else
            ElevatedButton(
              onPressed: _working ? null : _setup2fa,
              child: _working
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enable 2FA'),
            ),
        ],
      ),
    );
  }
}

class _RiderApiScaffold extends StatelessWidget {
  const _RiderApiScaffold({
    required this.title,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.child,
  });

  final String title;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF5F2D82),
        title: Text(title, style: const TextStyle(fontFamily: 'TT Fors')),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5F2D82)))
          : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!, textAlign: TextAlign.center),
                      TextButton(onPressed: onRetry, child: const Text('Retry')),
                    ],
                  ),
                )
              : child,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'TT Fors', color: Colors.grey)),
          Text(value, style: const TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
