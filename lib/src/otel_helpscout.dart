// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_helpscout_suppression.dart';

const _tracerName = 'dartastic_otel_libs_helpscout';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class HelpscoutResult {
  /// Creates a result.
  const HelpscoutResult({
    this.itemCount,
    this.totalElements,
    this.totalPages,
    this.mailboxId,
    this.conversationType,
    this.status,
    this.assigneeKind,
    this.rateLimitRemaining,
    this.requestId,
    this.statusCode,
  });

  /// `_embedded[*].length`.
  final int? itemCount;

  /// `page.totalElements`.
  final int? totalElements;

  /// `page.totalPages`.
  final int? totalPages;

  /// Mailbox id (HS bills per active user, but mailbox slices traffic).
  final int? mailboxId;

  /// `email` / `chat` / `phone`.
  final String? conversationType;

  /// `active` / `pending` / `closed` / `spam` / `open`.
  final String? status;

  /// `user` (agent) / `team` / `none`.
  final String? assigneeKind;

  /// `X-RateLimit-Remaining-Minute`.
  final int? rateLimitRemaining;

  /// `X-RateLimit-Request-Id` style.
  final String? requestId;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class HelpscoutCallResult<T> {
  /// Creates a call result.
  const HelpscoutCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final HelpscoutResult? result;
}

/// Wraps a Help Scout Mailbox v2 call in a CLIENT span. [operation] is
/// one of `conversations.list`, `conversations.get`,
/// `conversations.create`, `conversations.update`,
/// `conversations.assign`, `conversations.add_tag`,
/// `conversations.threads.create`, `conversations.threads.list`,
/// `customers.list`, `customers.create`, `customers.update`,
/// `mailboxes.list`, `workflows.list`, `workflows.run`,
/// `tags.list`, `webhooks.create`, `reports.conversations`.
Future<T> tracedHelpscout<T>({
  required String operation,
  required Future<HelpscoutCallResult<T>> Function() invoke,
}) async {
  if (helpscoutInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'helpscout',
    'rpc.method': operation,
    'helpscout.operation': operation,
  };

  final span = _tracer().startSpan(
    'helpscout $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTelAPI.attributeInt(
          'helpscout.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.totalElements != null) {
        extras.add(OTelAPI.attributeInt(
          'helpscout.total_elements',
          r.result!.totalElements!,
        ));
      }
      if (r.result!.totalPages != null) {
        extras.add(OTelAPI.attributeInt(
          'helpscout.total_pages',
          r.result!.totalPages!,
        ));
      }
      if (r.result!.mailboxId != null) {
        extras.add(OTelAPI.attributeInt(
          'helpscout.mailbox.id',
          r.result!.mailboxId!,
        ));
      }
      if (r.result!.conversationType != null) {
        extras.add(OTelAPI.attributeString(
          'helpscout.conversation.type',
          r.result!.conversationType!,
        ));
      }
      if (r.result!.status != null) {
        extras.add(OTelAPI.attributeString(
          'helpscout.status',
          r.result!.status!,
        ));
      }
      if (r.result!.assigneeKind != null) {
        extras.add(OTelAPI.attributeString(
          'helpscout.assignee.kind',
          r.result!.assigneeKind!,
        ));
      }
      if (r.result!.rateLimitRemaining != null) {
        extras.add(OTelAPI.attributeInt(
          'helpscout.rate_limit.remaining',
          r.result!.rateLimitRemaining!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTelAPI.attributeString(
          'helpscout.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Help Scout HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
