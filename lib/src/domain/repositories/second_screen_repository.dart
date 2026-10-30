import 'second_screen_display_manager.dart';
import 'second_screen_messenger.dart';
import 'second_screen_window_manager.dart';

/// Aggregated domain repository combining display discovery, window lifecycle,
/// and cross-screen messaging into a unified contract.
abstract interface class SecondScreenRepository
    implements
        SecondScreenDisplayManager,
        SecondScreenWindowManager,
        SecondScreenMessenger {}
