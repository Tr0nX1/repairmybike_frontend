import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service.dart';
import '../data/vehicles_api.dart';

class BookingFormState {
  final VehicleTypeItem? selectedType;
  final VehicleBrandItem? selectedBrand;
  final VehicleModelItem? selectedModel;
  final Service? selectedService;
  final DateTime? preferredDate;
  final String? preferredTime;
  final String? notes;
  final String? address;
  final String serviceLocation;

  BookingFormState({
    this.selectedType,
    this.selectedBrand,
    this.selectedModel,
    this.selectedService,
    this.preferredDate,
    this.preferredTime,
    this.notes,
    this.address,
    this.serviceLocation = 'home',
  });

  BookingFormState copyWith({
    VehicleTypeItem? selectedType,
    VehicleBrandItem? selectedBrand,
    VehicleModelItem? selectedModel,
    Service? selectedService,
    DateTime? preferredDate,
    String? preferredTime,
    String? notes,
    String? address,
    String? serviceLocation,
  }) {
    return BookingFormState(
      selectedType: selectedType ?? this.selectedType,
      selectedBrand: selectedBrand ?? this.selectedBrand,
      selectedModel: selectedModel ?? this.selectedModel,
      selectedService: selectedService ?? this.selectedService,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTime: preferredTime ?? this.preferredTime,
      notes: notes ?? this.notes,
      address: address ?? this.address,
      serviceLocation: serviceLocation ?? this.serviceLocation,
    );
  }
}

class BookingFormNotifier extends Notifier<BookingFormState> {
  @override
  BookingFormState build() {
    return BookingFormState();
  }

  void updateType(VehicleTypeItem? type) {
    state = state.copyWith(selectedType: type, selectedBrand: null, selectedModel: null);
  }

  void updateBrand(VehicleBrandItem? brand) {
    state = state.copyWith(selectedBrand: brand, selectedModel: null);
  }

  void updateModel(VehicleModelItem? model) {
    state = state.copyWith(selectedModel: model);
  }

  void updateService(Service? service) {
    state = state.copyWith(selectedService: service);
  }

  void updateDate(DateTime? date) {
    state = state.copyWith(preferredDate: date);
  }

  void updateTime(String? time) {
    state = state.copyWith(preferredTime: time);
  }

  void updateNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void updateAddress(String? address) {
    state = state.copyWith(address: address);
  }

  void updateLocation(String location) {
    state = state.copyWith(serviceLocation: location);
  }

  void reset() {
    state = BookingFormState();
  }
}

final bookingFormProvider = NotifierProvider<BookingFormNotifier, BookingFormState>(BookingFormNotifier.new);
