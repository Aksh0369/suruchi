// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(allReminders)
final allRemindersProvider = AllRemindersProvider._();

final class AllRemindersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Reminder>>,
          List<Reminder>,
          Stream<List<Reminder>>
        >
    with $FutureModifier<List<Reminder>>, $StreamProvider<List<Reminder>> {
  AllRemindersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allRemindersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allRemindersHash();

  @$internal
  @override
  $StreamProviderElement<List<Reminder>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Reminder>> create(Ref ref) {
    return allReminders(ref);
  }
}

String _$allRemindersHash() => r'32e2c872a1d3f4693e14b838ca0b5fa6eb129809';

@ProviderFor(remindersByCategory)
final remindersByCategoryProvider = RemindersByCategoryFamily._();

final class RemindersByCategoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Reminder>>,
          List<Reminder>,
          Stream<List<Reminder>>
        >
    with $FutureModifier<List<Reminder>>, $StreamProvider<List<Reminder>> {
  RemindersByCategoryProvider._({
    required RemindersByCategoryFamily super.from,
    required ReminderCategory super.argument,
  }) : super(
         retry: null,
         name: r'remindersByCategoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$remindersByCategoryHash();

  @override
  String toString() {
    return r'remindersByCategoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Reminder>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Reminder>> create(Ref ref) {
    final argument = this.argument as ReminderCategory;
    return remindersByCategory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RemindersByCategoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$remindersByCategoryHash() =>
    r'8ade62b14dbb29d9ebe39382191e839614546acf';

final class RemindersByCategoryFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Reminder>>, ReminderCategory> {
  RemindersByCategoryFamily._()
    : super(
        retry: null,
        name: r'remindersByCategoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RemindersByCategoryProvider call(ReminderCategory category) =>
      RemindersByCategoryProvider._(argument: category, from: this);

  @override
  String toString() => r'remindersByCategoryProvider';
}
