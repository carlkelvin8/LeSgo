import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/responsive_utils.dart';

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
