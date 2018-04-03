require 'thread'
NB_FLOORS = 10

class ElevatorCall
    attr_reader :nb, :source_floor, :going_up
    def initialize(nb, source_floor, going_up)
        @nb = nb
        @source_floor = source_floor
        @going_up = going_up
    end
    def to_s
        "Call from person #{nb} at floor #{@source_floor} going #{@going_up ? "up" : "down"}"
    end
end

class ElevatorRider
    attr_reader :nb, :dest_floor
    def initialize(nb)
        @nb = nb
        @dest_floor = nil
    end
    def gets_in(going_up, current_floor)
        if going_up
            @dest_floor = Random.rand(current_floor+1..NB_FLOORS)
        else
            @dest_floor = Random.rand(0..current_floor-1)
        end
        puts "Person #{@nb} gets in, is going to floor #{@dest_floor}"
    end
end

class Elevator
    attr_reader :current_floor, :going_up, :calls, :riders, :dest_floor
    def initialize
        @current_floor = 0
        @dest_floor = 0
        @calls = {}
        @riders = []
        @going_up = true
        @mutex = Mutex.new
    end
    def run
        while 42
            sleep(1)
            @mutex.synchronize {
                if @riders.empty? && @calls.empty?
                    puts "Elevator is at floor #{@current_floor}"
                end
            }
            @mutex.synchronize {
                while @current_floor != @dest_floor
                    # @going_up = @dest_floor > @current_floor ? true : false
                    @going_up ? @current_floor +=1 : @current_floor -= 1
                    puts "Elevator going to floor #{@current_floor}"
                    if @calls[@current_floor]
                        @calls[@current_floor].each { |call| 
                            if call.going_up == @going_up && call.source_floor == @current_floor
                                rider = ElevatorRider.new(call.nb)
                                rider.gets_in(call.going_up, @current_floor)
                                if !riders.include?(rider)
                                    @riders << rider
                                    if @calls[call.source_floor].length > 1
                                        @calls[call.source_floor].delete_at(call.nb - 1)
                                    else
                                        @calls.delete(call.source_floor)
                                    end
                                end
                                if @dest_floor == @current_floor
                                    @dest_floor = rider.dest_floor
                                end
                            end
                        }
                    end
                    @riders.each { |rider| 
                        if rider.dest_floor == @current_floor
                            puts "Person #{rider.nb} gets out at floor #{@current_floor}"
                            riders.delete(rider)
                        end
                    }
                end
            }
    end
end
    def insert_call(call)
        @mutex.synchronize {
            if @riders.empty?
                @dest_floor = call.source_floor
            end
            @calls[call.source_floor] ||= []
            @calls[call.source_floor] << call
        }
    end
end

def generate_call(elevator)
    i = 1
    while 42
        source_floor = gets.to_i
        call = ElevatorCall.new(i, source_floor, [true, false].sample)
        i += 1
        elevator.insert_call(call)
        puts call
    end
end

def main
    elevator = Elevator.new
    threads = []
    threads << Thread.new {elevator.run}
    threads << Thread.new {generate_call(elevator)}
    threads.each { |thread| thread.join }    
end

main()