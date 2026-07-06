/// Web/preview : câble « branché » simulé (pas de dart:io, pas de matériel).
Stream<bool> ethernetConnected() => Stream.value(true);
