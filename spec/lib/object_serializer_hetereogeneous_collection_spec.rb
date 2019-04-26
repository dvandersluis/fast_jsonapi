require 'spec_helper'

describe FastJsonapi::ObjectSerializer do
  class Vehicle
    attr_accessor :id, :model, :year

    def type
      self.class.name.downcase
    end
  end

  class Car < Vehicle
    attr_accessor :purchased_at
  end

  class Bus < Vehicle
    attr_accessor :passenger_count
  end

  class Truck < Vehicle
    attr_accessor :load
  end

  class VehicleSerializer
    include FastJsonapi::ObjectSerializer
    attributes :model, :year
  end

  class CarSerializer < VehicleSerializer
    include FastJsonapi::ObjectSerializer
    attribute :purchased_at
  end

  class BusSerializer < VehicleSerializer
    include FastJsonapi::ObjectSerializer
    attribute :passenger_count
  end

  class CollectionSerializer
    include FastJsonapi::ObjectSerializer
    set_class_serializers Car: CarSerializer, Bus: BusSerializer
  end

  class CollectionWithDefaultSerializer
    include FastJsonapi::ObjectSerializer
    set_class_serializers default: VehicleSerializer
  end

  let(:car) do
    car = Car.new
    car.id = 1
    car.model = 'Toyota Corolla'
    car.year = 1987
    car.purchased_at = Time.new(2018, 1, 1)
    car
  end

  let(:bus) do
    bus = Bus.new
    bus.id = 2
    bus.model = 'Nova Bus LFS'
    bus.year = 2014
    bus.passenger_count = 60
    bus
  end

  let(:truck) do
    truck = Truck.new
    truck.id = 3
    truck.model = 'Ford F150'
    truck.year = 2000
    truck
  end

  context 'when serializing a heterogenous collection' do
    it 'should use the correct serializers for each item' do
      vehicles = CollectionSerializer.new([car, bus]).to_hash
      car, bus = vehicles[:data]

      expect(car[:type]).to eq(:car)
      expect(car[:attributes]).to eq(model: 'Toyota Corolla', year: 1987, purchased_at: Time.new(2018, 1, 1))

      expect(bus[:type]).to eq(:bus)
      expect(bus[:attributes]).to eq(model: 'Nova Bus LFS', year: 2014, passenger_count: 60)
    end

    context 'if there is no serializer given for the class' do
      it 'should use the default serializer if specified' do
        data = CollectionWithDefaultSerializer.new([truck]).to_hash[:data][0]
        expect(data[:type]).to eq(:vehicle)
        expect(data[:attributes]).to eq(model: 'Ford F150', year: 2000)
      end

      it 'should not use a specific serializer otherwise' do
        data = CollectionSerializer.new([truck]).to_hash[:data][0]
        expect(data[:type]).to eq(:collection)
        expect(data[:attributes]).to be_blank
      end
    end
  end
end
