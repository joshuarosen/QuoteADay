local sound <const> = playdate.sound

local synth = sound.synth.new(sound.kWaveSquare)
synth:setADSR(0.25, 0.1, 1, 0.375)
synth:setVolume(0.25)
-- Set pulse width
synth:setParameter(1, 0.5)

local lfo = sound.lfo.new(sound.kWaveSine)
lfo:setRate(10)
lfo:setDepth(0.035)
synth:setFrequencyMod(lfo)

local melodyTrack = sound.track.new()
melodyTrack:addNote(3, "D4", 2)
melodyTrack:addNote(4, "E4", 1)
melodyTrack:addNote(5, "F#4", 1)
melodyTrack:addNote(6, "A4", 1, 0.8)

local melodyInstrument = sound.instrument.new(synth)
melodyTrack:setInstrument(melodyInstrument)

local backingSynth = synth:copy()
backingSynth:setWaveform(sound.kWaveSine)

local backingTrack = sound.track.new()
backingTrack:addNote(1, "D2", 8, 0.35)
local backingInstrument = sound.instrument.new(backingSynth)
backingTrack:setInstrument(backingInstrument)

local lowPassEffect = sound.onepolefilter.new()
lowPassEffect:setMix(0.8)
lowPassEffect:setParameter(-0.8)

local channel = sound.channel.new()
channel:addEffect(lowPassEffect)
channel:setVolume(0.75)
channel:addSource(melodyInstrument)
channel:addSource(backingInstrument) 

local jingleSequence = sound.sequence.new()
jingleSequence:addTrack(melodyTrack)
jingleSequence:addTrack(backingTrack)
jingleSequence:setTempo(10)

function playIntroJingle()
    jingleSequence:play()
end