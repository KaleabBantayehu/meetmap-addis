class PageResult<T> {
  final List<T> items;
  final String? nextCursor;
  final bool hasMore;

  const PageResult({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });
}
