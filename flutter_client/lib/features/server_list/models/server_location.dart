// lib/features/server_list/models/server_location.dart

class CloudRegion {
  final String id;
  final String name;
  final String provider;
  final String continent;

  const CloudRegion({
    required this.id,
    required this.name,
    required this.provider,
    required this.continent,
  });
}

class CloudProvider {
  final String name;
  final String code;
  final List<CloudRegion> regions;

  const CloudProvider({
    required this.name,
    required this.code,
    required this.regions,
  });
}

// 미리 정의된 클라우드 제공자 및 리전
final cloudProviders = [
  CloudProvider(
    name: 'Amazon Web Services',
    code: 'aws',
    regions: [
      CloudRegion(
        id: 'us-east-1',
        name: 'US East (N. Virginia)',
        provider: 'aws',
        continent: 'NA',
      ),
      CloudRegion(
        id: 'ap-northeast-2',
        name: 'Asia Pacific (Seoul)',
        provider: 'aws',
        continent: 'AS',
      ),
      CloudRegion(
        id: 'eu-west-1',
        name: 'Europe (Ireland)',
        provider: 'aws',
        continent: 'EU',
      ),
    ],
  ),
  CloudProvider(
    name: 'Google Cloud',
    code: 'gcp',
    regions: [
      CloudRegion(
        id: 'us-central1',
        name: 'Iowa, USA',
        provider: 'gcp',
        continent: 'NA',
      ),
      CloudRegion(
        id: 'asia-northeast3',
        name: 'Seoul, South Korea',
        provider: 'gcp',
        continent: 'AS',
      ),
    ],
  ),
  CloudProvider(
    name: 'Microsoft Azure',
    code: 'azure',
    regions: [
      CloudRegion(
        id: 'koreacentral',
        name: 'Korea Central',
        provider: 'azure',
        continent: 'AS',
      ),
      CloudRegion(
        id: 'westeurope',
        name: 'West Europe',
        provider: 'azure',
        continent: 'EU',
      ),
    ],
  ),
];
