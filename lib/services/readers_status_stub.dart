import '../models/reader_info.dart';

/// Web/preview : liste mock, gatectl « joignable ».
Stream<ReadersSnapshot> readersSnapshots(String serverIp) =>
    Stream<ReadersSnapshot>.value(
        ReadersSnapshot(readers: ReaderInfo.mock(), reachable: true));
