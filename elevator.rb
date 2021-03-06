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
        "Call from person #{@nb} at floor #{@source_floor} going #{@going_up ? "up" : "down"}"
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

    def to_s
        "Person #{@nb} -> floor #{@dest_floor}"
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

    def insert_call(call)
        @mutex.synchronize {
            @calls[call.source_floor] ||= []
            @calls[call.source_floor] << call
        }
    end

    def print_floor
        @mutex.synchronize {
            if @riders.empty? && @calls.empty?
                puts "Elevator is at floor #{@current_floor}"
            else
            print "Elevator going to floor #{@current_floor} | "
            @riders.each { | rider |
                if rider.dest_floor
                    print "#{rider.to_s} | "
                end
            }
            print "\n"
            end
        }
    end

    def take_passengers
        @mutex.synchronize {
            to_delete = []
            if @calls[@current_floor]
                @calls[@current_floor].each.with_index { |call, index|
                    if (@going_up == call.going_up && call.source_floor == @current_floor )|| @current_floor == @dest_floor #If a call is on my way or I reached the current call
                        rider = ElevatorRider.new(call.nb)
                        rider.gets_in(call.going_up, @current_floor)
                        @riders << rider
                        if (@going_up && rider.dest_floor < @dest_floor) || (!@going_up && rider.dest_floor > @dest_floor)
                            @dest_floor = rider.dest_floor
                        end
                        to_delete.unshift(index)
                        if @current_floor == @dest_floor  #If I have nowhere else to go, drop this person first
                            @dest_floor = rider.dest_floor
                        end
                    end
                }
            end
            to_delete.each { |index|
                if @calls[@current_floor].length > 1
                    @calls[@current_floor].delete_at(index)
                else
                    @calls.delete(@current_floor)
                end
            }
        }
    end

    def leave_passengers
        @mutex.synchronize {
            to_delete = []
            @riders.each.with_index { |rider, index| 
                if rider.dest_floor == @current_floor
                    puts "Person #{rider.nb} gets out at floor #{@current_floor}"
                    to_delete.unshift(index)
                end
            }
            to_delete.each { |index| @riders.delete_at(index) }
        }
    end

    def get_destination
        @mutex.synchronize {
            if @current_floor == @dest_floor && !@riders.empty? #If there are people in the elevator, drop the nearest one
                @dest_floor = @riders[0].dest_floor
                @riders.each { | rider |
                    if rider.dest_floor && ((@going_up && rider.dest_floor < @dest_floor) || (!@going_up && rider.dest_floor > @dest_floor))
                        @dest_floor = rider.dest_floor
                    end
                }
            elsif @current_floor == @dest_floor && @riders.empty? && !@calls.empty? #If the elevator is empty, get to next call's floor
                oldest_call = @calls.values[0][0]
                @calls.each { | source_floor, floor_calls |
                    floor_calls.each { | call |
                        if call.nb < oldest_call.nb
                            oldest_call = call
                        end
                    }
                }
                @dest_floor = oldest_call.source_floor
            end
        }
    end

    def run
        loop do
            print_floor()
            sleep(2)
            take_passengers()
            get_destination()
            while @current_floor != @dest_floor && @current_floor >= 0 && @current_floor <= NB_FLOORS
                @going_up = @dest_floor > @current_floor ? true : false
                @going_up ? @current_floor +=1 : @current_floor -= 1
                print_floor()
                take_passengers()
                leave_passengers()
                get_destination()
                sleep(2)
            end
        end
    end

end

def generate_calls(elevator)
    i = 1
    loop do
        sleep(Random.rand(4..15))
        source_floor = Random.rand(0..NB_FLOORS)
        if source_floor == 0
            going_up = true
        elsif source_floor == NB_FLOORS
            going_up = false
        else
            going_up = [true, false].sample
        end
        call = ElevatorCall.new(i, source_floor, going_up)
        i += 1
        elevator.insert_call(call)
        puts call
    end
end

def main
    elevator = Elevator.new
    threads = []
    threads << Thread.new {elevator.run()}
    threads << Thread.new {generate_calls(elevator)}
    threads.each { |thread| thread.join }
end

main()