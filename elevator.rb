NB_FLOORS = 10

class ElevatorCall
    attr_reader :nb, :source_floor, :going_up, :dest_floor
    def initialize(nb, source_floor, going_up)
        @nb = nb
        @source_floor = source_floor
        @going_up = going_up
        @dest_floor = nil
    end
    def to_s
        "Call from #{@source_floor} going #{@going_up ? "up" : "down"}"
    end
end

class Elevator
    attr_reader :current_floor, :going_up, :calls_up, :calls_down
    def initialize
        @current_floor = 0
        @calls_up = {}
        @calls_down = {}
        @current_call = nil
        @going_up = true
        @mutex = Mutex.new
    end
    def run
        while 42
            sleep(1)
            @mutex.synchronize {
                if @calls_up.empty? && @calls_down.empty?
                    puts "L'ascenseur est au #{@current_floor}"
                end
                if @current_call
                    while @current_floor != @current_call.source_floor
                        @current_floor += 1
                        puts "L'ascenseur va au #{@current_floor}"
                        sleep(1)
                    end
                    if @current_call.going_up
                        @current_call.dest_floor = Random.rand(@current_floor+1..NB_FLOORS)
                    else
                        @current_call.dest_floor = Random.rand(0..@current_floor-1)
                    end
                    puts "la personne va à l'étage #{@current_call.dest_floor}"
                    while @current_floor != @current_call.dest_floor
                        @current_call.going_up ? @current_floor += 1 : @current_floor -=1
                        puts "L'ascenseur va au #{@current_floor}"
                        sleep(1)
                    end
                    @current_call = nil
                end
            }
        end
    end
    def insert_call(call)
        if @current_call == nil
            @current_call = call
        else
            @mutex.synchronize {
                if call.going_up
                    @calls_up[call.source_floor] ||= []
                    @calls_up[call.source_floor] << call
                else
                    @calls_down[call.source_floor] ||= []
                    @calls_down[call.source_floor] << call
                end
            }
        end
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
    call = ElevatorCall.new(3, false)
    threads = []
    threads << Thread.new {elevator.run}
    threads << Thread.new {generate_call(elevator)}
    threads.each { |thread| thread.join }    
end

main()