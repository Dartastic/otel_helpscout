// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_helpscout/otel_helpscout.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_helpscout-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('conversations.list records mailbox + status + rate limit', () async {
    await tracedHelpscout<String>(
      operation: 'conversations.list',
      invoke: () async => const HelpscoutCallResult(
        value: 'ok',
        result: HelpscoutResult(
          itemCount: 25,
          totalElements: 412,
          totalPages: 17,
          mailboxId: 1024,
          conversationType: 'email',
          status: 'open',
          assigneeKind: 'user',
          rateLimitRemaining: 142,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('helpscout conversations.list')!);
    expect(a['helpscout.mailbox.id'], 1024);
    expect(a['helpscout.conversation.type'], 'email');
    expect(a['helpscout.status'], 'open');
    expect(a['helpscout.assignee.kind'], 'user');
    expect(a['helpscout.rate_limit.remaining'], 142);
  });

  test('suppression skips spans', () async {
    await runWithoutHelpscoutInstrumentationAsync(() async {
      await tracedHelpscout<String>(
        operation: 'mailboxes.list',
        invoke: () async => const HelpscoutCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('helpscout '), isEmpty);
  });
}
