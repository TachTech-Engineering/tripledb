// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trivia_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$triviaFactsHash() => r'db2f6bd592493b8b68ddd1232ef8671860c74127';

/// See also [TriviaFacts].
@ProviderFor(TriviaFacts)
final triviaFactsProvider =
    AutoDisposeNotifierProvider<TriviaFacts, List<String>>.internal(
      TriviaFacts.new,
      name: r'triviaFactsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$triviaFactsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TriviaFacts = AutoDisposeNotifier<List<String>>;
String _$currentTriviaIndexHash() =>
    r'5cecd79b5443e101ee4c01040e9806ab7ed06960';

/// See also [CurrentTriviaIndex].
@ProviderFor(CurrentTriviaIndex)
final currentTriviaIndexProvider =
    AutoDisposeNotifierProvider<CurrentTriviaIndex, int>.internal(
      CurrentTriviaIndex.new,
      name: r'currentTriviaIndexProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentTriviaIndexHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CurrentTriviaIndex = AutoDisposeNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
