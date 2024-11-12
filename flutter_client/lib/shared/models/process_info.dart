// lib/shared/models/process_info.dart

class ProcessInfo {
  final String name;
  final double cpu;
  final double memory;
  final String network;
  final int pid;

  // const 생성자 추가
  const ProcessInfo({
    required this.name,
    required this.cpu,
    required this.memory,
    required this.network,
    required this.pid,
  });

  factory ProcessInfo.fromJson(Map<String, dynamic> json) {
    return ProcessInfo(
      name: json['name'],
      cpu: json['cpu'].toDouble(),
      memory: json['memory'].toDouble(),
      network: json['network'],
      pid: json['pid'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'cpu': cpu,
        'memory': memory,
        'network': network,
        'pid': pid,
      };
}
