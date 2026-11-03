Future<(A, B)> waitBoth<A, B>(Future<A> first, Future<B> second) async {
  final results = await Future.wait<Object?>([first, second]);
  return (results[0] as A, results[1] as B);
}
