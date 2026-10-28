// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_helpscout/otel_helpscout.dart';

/// Traces Help Scout Mailbox v2 calls with OpenTelemetry.
///
/// `otel_helpscout` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Help Scout Mailbox v2 call in
/// [tracedHelpscout]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'helpscout-example');

  // Wraps a Help Scout Mailbox v2 call in a CLIENT span.
  final helpscoutId = await tracedHelpscout<String>(
    operation: 'conversations.create',
    invoke: () async {
      // Make the Help Scout Mailbox v2 call here, then report what it returned.
      const id = 'helpscout_8f3a2c';
      return const HelpscoutCallResult(
          value: id,
          result: HelpscoutResult(
              itemCount: 3,
              totalElements: 1,
              totalPages: 1,
              mailboxId: 1,
              conversationType: 'email',
              status: 'active',
              assigneeKind: 'user',
              rateLimitRemaining: 25,
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedHelpscout conversations.create returned $helpscoutId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutHelpscoutInstrumentationAsync.
  await runWithoutHelpscoutInstrumentationAsync(
    () => tracedHelpscout<String>(
      operation: 'conversations.create',
      invoke: () async {
        const id = 'helpscout_8f3a2c';
        return const HelpscoutCallResult(
            value: id,
            result: HelpscoutResult(
                itemCount: 3,
                totalElements: 1,
                totalPages: 1,
                mailboxId: 1,
                conversationType: 'email',
                status: 'active',
                assigneeKind: 'user',
                rateLimitRemaining: 25,
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
