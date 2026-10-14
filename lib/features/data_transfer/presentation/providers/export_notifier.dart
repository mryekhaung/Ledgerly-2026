import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/core/period/budget_period.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/export_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/usecases/export_transactions.dart';

class ExportState {
  const ExportState({
    this.filter = const ExportFilter(),
    this.period,
    this.isLoading = false,
    this.exportedData,
    this.failure,
    this.isCopied = false,
  });

  final ExportFilter filter;
  final BudgetPeriod? period;
  final bool isLoading;
  final ExportData? exportedData;
  final Failure? failure;
  final bool isCopied;

  ExportState copyWith({
    ExportFilter? filter,
    BudgetPeriod? period,
    bool? isLoading,
    ExportData? exportedData,
    Failure? failure,
    bool? isCopied,
    bool clearExportedData = false,
    bool clearFailure = false,
  }) {
    return ExportState(
      filter: filter ?? this.filter,
      period: period ?? this.period,
      isLoading: isLoading ?? this.isLoading,
      exportedData: clearExportedData
          ? null
          : (exportedData ?? this.exportedData),
      failure: clearFailure ? null : (failure ?? this.failure),
      isCopied: isCopied ?? this.isCopied,
    );
  }
}

class ExportNotifier extends Notifier<ExportState> {
  ExportNotifier({this.exportUseCase});

  final ExportTransactions? exportUseCase;

  @override
  ExportState build() => const ExportState();

  void setFormat(ExportFormat format) {
    state = state.copyWith(
      filter: state.filter.copyWith(format: format),
      clearExportedData: true,
      clearFailure: true,
      isCopied: false,
    );
  }

  void setRangePreset(ExportRangePreset preset) {
    state = state.copyWith(
      filter: state.filter.copyWith(rangePreset: preset),
      clearExportedData: true,
      clearFailure: true,
      isCopied: false,
    );
  }

  void setPeriod(BudgetPeriod period) {
    state = state.copyWith(
      period: period,
      filter: state.filter.copyWith(
        customStartDate: period.start.value,
        customEndDate: period.end.value,
      ),
      clearExportedData: true,
      clearFailure: true,
      isCopied: false,
    );
  }

  void setCustomDates(LocalDate start, LocalDate end) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        rangePreset: ExportRangePreset.custom,
        customStartDate: start.value,
        customEndDate: end.value,
      ),
      clearExportedData: true,
      clearFailure: true,
      isCopied: false,
    );
  }

  Future<void> export() async {
    final useCase = exportUseCase;
    if (useCase == null) return;

    state = state.copyWith(
      isLoading: true,
      clearFailure: true,
      isCopied: false,
    );

    final result = await useCase(state.filter);
    state = switch (result) {
      Success(:final value) => state.copyWith(
        isLoading: false,
        exportedData: value,
      ),
      Err(:final failure) => state.copyWith(isLoading: false, failure: failure),
    };
  }

  void markCopied(bool copied) {
    state = state.copyWith(isCopied: copied);
  }

  void reset() {
    state = const ExportState();
  }
}
