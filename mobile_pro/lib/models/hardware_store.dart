class HardwareStore {
  final String id;
  final String name;
  final String commune;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final List<String> specialties;

  const HardwareStore({
    required this.id,
    required this.name,
    required this.commune,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.specialties,
  });
}

const List<HardwareStore> kDakarHardwareStores = [
  HardwareStore(
    id: 'hw_sandaga',
    name: 'Quincaillerie Touba Sandaga',
    commune: 'Dakar Plateau',
    address: 'Avenue Lamine Guèye x Sandaga',
    latitude: 14.6685,
    longitude: -17.4365,
    phone: '+221 33 821 45 10',
    specialties: ['Électricité', 'Plomberie', 'Outillage'],
  ),
  HardwareStore(
    id: 'hw_medina',
    name: 'Quincaillerie Moderne Médina',
    commune: 'Médina',
    address: 'Rue 22 x Avenue Blaise Diagne',
    latitude: 14.6852,
    longitude: -17.4520,
    phone: '+221 33 822 14 55',
    specialties: ['Plomberie', 'Tuyauterie', 'Sanitaire'],
  ),
  HardwareStore(
    id: 'hw_pointe',
    name: 'Quincaillerie & Sanitaire Point E',
    commune: 'Point E / Fann',
    address: 'Rue de Diourbel, près Piscine Olympique',
    latitude: 14.6934,
    longitude: -17.4640,
    phone: '+221 33 825 60 90',
    specialties: ['Électricité', 'Sanitaire', 'Climatisation'],
  ),
  HardwareStore(
    id: 'hw_castors',
    name: 'Comptoir Matériel Castors',
    commune: 'Castors',
    address: 'Avenue Bourguiba face Marché Castors',
    latitude: 14.7080,
    longitude: -17.4510,
    phone: '+221 33 824 10 32',
    specialties: ['Plomberie BTP', 'Câblage', 'Outillage Pro'],
  ),
  HardwareStore(
    id: 'hw_ouakam',
    name: 'Quincaillerie Générale Ouakam',
    commune: 'Ouakam',
    address: 'Route de Ouakam, Cité Comico',
    latitude: 14.7215,
    longitude: -17.4880,
    phone: '+221 33 860 33 21',
    specialties: ['Électricité', 'Peinture', 'Quincaillerie'],
  ),
  HardwareStore(
    id: 'hw_almadies',
    name: 'Quincaillerie Express Almadies',
    commune: 'Almadies',
    address: 'Route des Almadies près King Fahd',
    latitude: 14.7430,
    longitude: -17.5120,
    phone: '+221 33 869 12 00',
    specialties: ['Climatisation', 'Sanitaire de Luxe', 'Électrique'],
  ),
  HardwareStore(
    id: 'hw_grandyoff',
    name: 'Quincaillerie Centrale Grand Yoff',
    commune: 'Grand Yoff',
    address: 'Tally Boubess, Grand Yoff',
    latitude: 14.7290,
    longitude: -17.4550,
    phone: '+221 33 827 44 80',
    specialties: ['Plomberie', 'Serrurerie', 'BTP'],
  ),
  HardwareStore(
    id: 'hw_parcelles',
    name: 'Quincaillerie Moderne Parcelles',
    commune: 'Parcelles Assainies',
    address: 'Unité 20, près Rond-point Case Bi',
    latitude: 14.7540,
    longitude: -17.4380,
    phone: '+221 33 835 11 22',
    specialties: ['Électricité', 'Plomberie', 'Tuyaux PVC'],
  ),
  HardwareStore(
    id: 'hw_pikine',
    name: 'Quincaillerie Pikine Icotaf',
    commune: 'Pikine',
    address: 'Tally Boumack, Pikine Icotaf',
    latitude: 14.7550,
    longitude: -17.3980,
    phone: '+221 33 834 50 10',
    specialties: ['Fer forgé', 'Serrurerie', 'Outillage BTP'],
  ),
  HardwareStore(
    id: 'hw_guediawaye',
    name: 'Quincaillerie Marché Jeudi',
    commune: 'Guédiawaye',
    address: 'Marché Jeudi, Guédiawaye',
    latitude: 14.7730,
    longitude: -17.3910,
    phone: '+221 33 837 02 44',
    specialties: ['Électricité', 'Plomberie', 'Peinture'],
  ),
  HardwareStore(
    id: 'hw_keurmassar',
    name: 'Quincaillerie Keur Massar Mtoa',
    commune: 'Keur Massar',
    address: 'Route des Niayes, Keur Massar',
    latitude: 14.7830,
    longitude: -17.3110,
    phone: '+221 33 878 90 00',
    specialties: ['Matériel Dépannage', 'Électrique', 'Sanitaire'],
  ),
];
