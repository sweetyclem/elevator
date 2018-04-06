require 'thread'
NB_FLOORS = 10

class ElevatorCall
	attr_reader :nb, :source_floor, :going_up
	attr_accessor :dest_floor

    def initialize(nb, source_floor, going_up, dest_floor)
        @nb = nb
        @source_floor = source_floor
		@going_up = going_up
		@dest_floor = dest_floor
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

    def gets_in(going_up, current_floor, dest)
        @dest_floor = dest
        puts "Person #{@nb} gets in, is going to floor #{@dest_floor}"
    end

    def to_s
        "Person #{@nb} -> floor #{@dest_floor}"
    end

end

class Elevator
    attr_reader :count, :current_floor, :going_up, :calls, :riders, :dest_floor

	def initialize
		@count = 1
        @current_floor = 0
        @dest_floor = 0
        @calls = {}
        @riders = []
        @going_up = true
        @mutex = Mutex.new
    end

    def generate_calls
		loop do
			source_floor = gets.to_i
			dest_floor = gets.to_i
			going_up = source_floor < dest_floor ? true : false
			call = ElevatorCall.new(@count, source_floor, going_up, dest_floor)
			@count += 1
			insert_call(call)
			puts call
		end
    end
    
    def insert_call(call)
        @mutex.synchronize {
            if @riders.empty?
                @dest_floor = call.source_floor
                rider = ElevatorRider.new(call.nb)
                @riders << rider
            end
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
                    if (@going_up == call.going_up && call.source_floor == @current_floor )|| @current_floor == @dest_floor
                        if @riders.any?{|r| r.nb == call.nb}
                            rider = @riders[@riders.find_index {|r| r.nb == call.nb}]
                            rider.gets_in(call.going_up, @current_floor, call.dest_floor)
                            if (@going_up && rider.dest_floor < @dest_floor) || (!@going_up && rider.dest_floor > @dest_floor)
                                @dest_floor = rider.dest_floor
                            end
                        else
                            rider = ElevatorRider.new(call.nb)
                            rider.gets_in(call.going_up, @current_floor, call.dest_floor)
                            @riders << rider
                            if (@going_up && rider.dest_floor < @dest_floor) || (!@going_up && rider.dest_floor > @dest_floor)
                                @dest_floor = rider.dest_floor
                            end
                        end
                        to_delete.unshift(index)
                        if @current_floor == @dest_floor
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
                puts "oldest call : #{oldest_call}"
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

def main
    elevator = Elevator.new
    threads = []
    threads << Thread.new {elevator.run()}
    threads << Thread.new {elevator.generate_calls}
    threads.each { |thread| thread.join }
end

main()
