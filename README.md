# Recusant-Godot4

-have implemented a fugly movement system
-can rotate camera with keyboard arrow keys and zoom in and out with mouse wheel
- clicking on tiles should log their coordinates as well as move the player avatar to that tile
- implemented first step of POI generation currently cities generate at random
- red lines between cities denote faction distance connections
- tan lines denote aStar pathifinding with cost increased based on elevation

# Next steps
- fix fugly movement so avatar goes to top of tile not y = 0
- implement more POI intelligence in instantiation
- begin generation of plant meshes based on humidity as opposed to the color ramp that is currently representing humidity
- add meshes for hills and mountains to denote them as a seperate biome as opposed to just a different color material

# ideation

world generation plan is a to have a 9 phase process

1. Elevation, and humidity are randomized noise based on seed values
2. biomes are generated then POI's are randomly distributed, then generate roads between major cities - roads are generated here
3. using state machine / grammar based rule set we fix poi's so they make sense from a constraint persepective
4. generate factions (diplomatic , titles, symbols, etc)
5. run simulation for N number of rounds where factions either take unclaimed territory, fight over territory, or ally with with neighbors
6. generate quest threads based on faction states
7. generate NPC's based on quest threads and POI distributions
8. organize quest patterns to be solvable based on NPC's quest threads, and pathing

