import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:nextcloud_deck/core/errors/exceptions.dart';
import 'package:nextcloud_deck/core/theme/app_colors.dart';
import 'package:nextcloud_deck/l10n/app_localizations.dart';
import 'package:nextcloud_deck/presentation/providers/app_providers.dart';
import 'package:nextcloud_deck/presentation/providers/auth_provider.dart';
import 'package:nextcloud_deck/presentation/widgets/app_icon_widget.dart';

enum _LoginStep { enterUrl, webview, polling }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _LoginStep _step = _LoginStep.enterUrl;
  String? _errorMessage;
  bool _loading = false;

  WebViewController? _webViewController;
  void Function()? _cancelPolling;

  @override
  void dispose() {
    _cancelPolling?.call();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _startLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final url = _urlController.text.trim();
    final authService = ref.read(authServiceProvider);

    try {
      final result = await authService.initiateLogin(
        url,
        AppLocalizations.of(context).appTitle,
      );
      _cancelPolling = result.cancel;

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(result.loginUrl));

      setState(() {
        _loading = false;
        _step = _LoginStep.webview;
        _webViewController = controller;
      });

      result.pollFuture
          .then((creds) async {
            if (!mounted) return;
            setState(() => _step = _LoginStep.polling);
            await authService.saveCredentials(creds);
            await ref
                .read(authProvider.notifier)
                .loginComplete(
                  serverUrl: creds.serverUrl,
                  username: creds.loginName,
                  appPassword: creds.appPassword,
                );
          })
          .catchError((Object error) {
            if (!mounted) return;
            setState(() {
              _step = _LoginStep.enterUrl;
              _errorMessage = _errorToString(
                error,
                AppLocalizations.of(context),
              );
            });
          });
    } on AppException catch (e) {
      setState(() {
        _loading = false;
        final l = AppLocalizations.of(context);

        _errorToString(e, l);
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _errorMessage = AppLocalizations.of(context).loginErrorGeneric;
      });
    }
  }

  /// Translates a caught exception into a user-facing, localised message.
  /// Auth errors from [AuthService] are mapped to specific l10n strings so
  /// that no English is ever hard-coded in the service layer.
  String _errorToString(Object error, AppLocalizations l10n) {
    if (error is PollTimeoutException) return l10n.loginPollingTimeout;
    if (error is AuthFlowException) {
      if (error.message.toLowerCase().contains('cancel')) {
        return l10n.loginCancelledByUser;
      }
      return l10n.loginErrorGeneric;
    }
    if (error is NetworkException) return l10n.loginErrorGeneric;
    if (error is AppException) return l10n.loginErrorGeneric;
    return l10n.loginErrorGeneric;
  }

  void _cancelLogin() {
    _cancelPolling?.call();
    setState(() {
      _step = _LoginStep.enterUrl;
      _errorMessage = null;
      _webViewController = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_step) {
          _LoginStep.webview => _buildWebView(context),
          _LoginStep.polling => _buildPolling(context),
          _LoginStep.enterUrl => _buildUrlEntry(context),
        },
      ),
    );
  }

  Widget _buildUrlEntry(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SafeArea(
        key: const ValueKey('url-entry'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AppIcon(size: 64, fallbackColor: AppColors.brand),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.appTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.loginTitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  textInputAction: TextInputAction.go,
                  onFieldSubmitted: (_) => _startLogin(),
                  decoration: InputDecoration(
                    labelText: l10n.loginUrlLabel,
                    hintText: l10n.loginServerUrlHint,
                    prefixIcon: const Icon(Icons.link_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return l10n.loginUrlValidationEmpty;
                    }
                    final uri = Uri.tryParse(val.trim());
                    if (uri == null || !uri.hasScheme) {
                      return l10n.loginUrlValidationScheme;
                    }
                    return null;
                  },
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _startLogin,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.loginConnect),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  l10n.loginApproveInfo,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const ValueKey('webview'),
      appBar: AppBar(
        title: Text(l10n.loginWebViewTitle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _cancelLogin,
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.infoLight,
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.brand,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.loginApproveInfo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: WebViewWidget(controller: _webViewController!)),
        ],
      ),
    );
  }

  Widget _buildPolling(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      key: const ValueKey('polling'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.brand),
            const SizedBox(height: 24),
            Text(
              l10n.loginPollingTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.loginWaitingForAuth,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
