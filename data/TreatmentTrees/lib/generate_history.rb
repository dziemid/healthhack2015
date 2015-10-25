require 'csv'
require 'ostruct'

class GenerateHistory

  def run(path)
    people = {}

    days = {}
    CSV.foreach(path) do |row|
      person = parse(row)
      people[person.id] = person unless people[person.id]
      people[person.id].stop_treatment ||= person.stop_treatment
      people[person.id].dead ||= person.dead

      puts "#{person.id};#{person.bmi};#{person.dead};#{person.sex};#{person.stop_treatment};#{person.diabetes};#{person.age};#{person.treatment};#{person.period};#{people[person.id].history}"

      people[person.id].history << person.treatment
    end
  end

  private

  def parse(row)
    person = OpenStruct.new
    person.id = row[0]
    person.age = row[1]
    person.diabetes = row[2]
    person.bmi = row[3]
    person.treatment = row[4].to_i
    person.dead = row[5] #!= "0"
    person.period = row[6]
    person.stop_treatment = row[7] #!= "0"
    person.sex = row[8]
    person.history = []
    person
  end

end

