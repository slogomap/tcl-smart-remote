import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcl_smart_remote/models/connection_state.dart';
import 'package:tcl_smart_remote/models/tv_command.dart';
import 'package:tcl_smart_remote/theme/app_theme.dart';
import 'package:tcl_smart_remote/widgets/remote_button.dart';
import 'package:tcl_smart_remote/widgets/remote_dpad.dart';
import 'package:tcl_smart_remote/widgets/status_bar_card.dart';

void main() {
  testWidgets('StatusBarCard renders title, TV name and status', (WidgetTester tester) async {
    const state = RemoteConnectionState(
      status: DeviceConnectionStatus.connected,
      activeDeviceName: 'TCL QLED 4K TV',
      activeDeviceIp: '192.168.1.155',
      batteryLevel: 88,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: StatusBarCard(
            connectionState: state,
            onTapTvStatus: () {},
          ),
        ),
      ),
    );

    expect(find.text('TCL SMART REMOTE'), findsOneWidget);
    expect(find.text('TCL QLED 4K TV'), findsOneWidget);
    expect(find.text('88%'), findsOneWidget);
  });

  testWidgets('RemoteDpad renders navigation controls and triggers callback', (WidgetTester tester) async {
    TvButtonType? pressedButton;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: RemoteDpad(
            onButtonPressed: (type, {direction = KeyDirection.click}) {
              pressedButton = type;
            },
          ),
        ),
      ),
    );

    expect(find.text('OK'), findsOneWidget);

    // Tap OK
    await tester.tap(find.text('OK'));
    await tester.pump();
    expect(pressedButton, equals(TvButtonType.dpadCenter));

    // Tap Up Arrow
    await tester.tap(find.byIcon(Icons.keyboard_arrow_up));
    await tester.pump();
    expect(pressedButton, equals(TvButtonType.dpadUp));
  });

  testWidgets('RemoteButton renders and responds to tap', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RemoteButton(
            icon: Icons.power_settings_new,
            style: RemoteButtonStyle.power,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.power_settings_new));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
