import '../models/user_model.dart';
import '../models/collection_schedule.dart';
import '../models/truck_location.dart';
import '../models/eco_report.dart';

class MockDataStore {
  static final UserModel currentUser = UserModel(
    uid: 'mock_user_001',
    fullName: 'J Vinodhini',
    email: 'jvinodhini006@gmail.com',
    wardNumber: 'Ward 195',
    ecoPoints: 1250,
  );

  static final List<CollectionSchedule> ward195Schedule = [
    const CollectionSchedule(id: 'sch_1', dayOfWeek: 'Monday',
      wasteType: 'Organic Waste', startTime: '08:00',
      endTime: '10:00', wardNumber: 'Ward 195'),
    const CollectionSchedule(id: 'sch_2', dayOfWeek: 'Tuesday',
      wasteType: 'Recyclable (Plastic/Metal)', startTime: '09:00',
      endTime: '11:00', wardNumber: 'Ward 195'),
    const CollectionSchedule(id: 'sch_3', dayOfWeek: 'Wednesday',
      wasteType: 'Paper & Cardboard', startTime: '08:30',
      endTime: '10:30', wardNumber: 'Ward 195'),
    const CollectionSchedule(id: 'sch_4', dayOfWeek: 'Thursday',
      wasteType: 'Organic Waste', startTime: '08:00',
      endTime: '10:00', wardNumber: 'Ward 195'),
    const CollectionSchedule(id: 'sch_5', dayOfWeek: 'Friday',
      wasteType: 'E-Waste & Batteries', startTime: '10:00',
      endTime: '12:00', wardNumber: 'Ward 195'),
    const CollectionSchedule(id: 'sch_6', dayOfWeek: 'Saturday',
      wasteType: 'Glass & Hazardous', startTime: '09:00',
      endTime: '11:00', wardNumber: 'Ward 195'),
    const CollectionSchedule(id: 'sch_7', dayOfWeek: 'Sunday',
      wasteType: 'No Collection', startTime: '',
      endTime: '', wardNumber: 'Ward 195'),
  ];

  static final TruckLocation activeTruck = TruckLocation(
    truckId: 'truck_001',
    truckNumber: 'KA-01-2345',
    driverName: 'Ramesh Kumar',
    latitude: 12.9716,
    longitude: 77.5946,
    currentAddress: '12th Cross, Rajajinagar',
    headingToWard: 'Ward 195',
    etaMinutes: 5,
    isActive: true,
    lastUpdated: DateTime.now(),
  );

  static final EcoReport report = EcoReport(
    userId: 'mock_user_001',
    totalEcoPoints: 1250,
    level: 'Level 4: Green Warrior',
    wasteSavedKg: 45.0,
    co2SavedKg: 12.0,
    recycledKg: 28.0,
    treesEquivalent: 2.5,
    weeklyConsistency: [true, true, false, true, true, false, false],
  );

  static final List<String> ecoTips = [
    'Rinse plastic containers before recycling them.',
    'Compost food scraps to reduce organic waste.',
    'Separate dry and wet waste before collection.',
    'Use cloth bags instead of plastic for shopping.',
    'Report missed collections to help improve service.',
  ];

  static final List<String> wardList = [
    'Ward 190', 'Ward 191', 'Ward 192', 'Ward 193',
    'Ward 194', 'Ward 195', 'Ward 196', 'Ward 197',
    'Ward 198', 'Ward 199', 'Ward 200',
  ];
}
