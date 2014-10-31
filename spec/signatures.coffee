expect = chai.expect
assert = chai.assert



describe 'Signatures', ->
    
    


  
  
  engine = null
  describe 'dispatched by argument types', ->
    PrimitiveCommand = GSS::Command.extend {
      signature: [
        left: ['String', 'Value']
        right: ['Number']
      ]
    }, {
      'primitive': () ->
    }
  
    before ->
      engine = new GSS
      engine.abstract.PrimitiveCommand = PrimitiveCommand
      engine.compile(true)
    
    describe 'with primitive', ->
      it 'should match property function definition', ->
        expect(engine.abstract.Command(['primitive', 'test'])).to.not.be.an.instanceof(PrimitiveCommand.primitive)
        expect(engine.abstract.Command(['primitive', 'test', 10])).to.be.an.instanceof(PrimitiveCommand.primitive)
        expect(engine.abstract.Command(['primitive', 'test', 'test'])).to.not.be.an.instanceof(PrimitiveCommand.primitive)
        expect(engine.abstract.Command(['undeclared', 'test', 10])).to.not.be.an.instanceof(PrimitiveCommand.primitive)
        expect(engine.abstract.Command(['undeclared', 'test', 'test'])).to.be.an.instanceof(engine.abstract.Default)

    describe 'with variables', ->
      it 'should match property function definition', ->
        expect(engine.abstract.Command(['primitive', ['get', 'test']])).to.not.be.an.instanceof(PrimitiveCommand.primitive)
        expect(engine.abstract.Command(['primitive', ['get', 'test'], 10])).to.be.an.instanceof(PrimitiveCommand.primitive)
        expect(engine.abstract.Command(['primitive', ['get', 'test'], 'test'])).to.not.be.an.instanceof(PrimitiveCommand.primitive)
        expect(engine.abstract.Command(['primitive', ['get', 'test'], ['get', 'test']])).to.not.be.an.instanceof(PrimitiveCommand.primitive)
        expect(engine.abstract.Command(['undeclared', ['get', 'test'], 10])).to.be.an.instanceof(engine.abstract.Default)
    
    describe 'with expressions', ->
      it 'should match property function definition', ->
        expect(engine.abstract.Command(['primitive', ['+',  ['get', 'test'], 1]])).to.not.be.an.instanceof(PrimitiveCommand.primitive)
        expect(engine.abstract.Command(['primitive', ['+',  ['get', 'test'], 1], 10])).to.be.an.instanceof(PrimitiveCommand.primitive)
        expect(engine.abstract.Command(['primitive', ['+',  ['get', 'test'], 1], 'test'])).to.not.be.an.instanceof(PrimitiveCommand.primitive)
        expect(engine.abstract.Command(['primitive', ['+',  ['get', 'test'], 1], ['+',  ['get', 'test'], 1]])).to.not.be.an.instanceof(PrimitiveCommand.primitive)
        expect(engine.abstract.Command(['undeclared', ['+',  ['get', 'test'], 1], 10])).to.be.an.instanceof(engine.abstract.Default)
  
  
  
  describe 'dispatched with optional arguments', ->
    UnorderedCommand = GSS::Command.extend {
      signature: [[
        left: ['String', 'Value']
        right: ['Number']
        mode: ['Number']
      ]]
    }, {
      'unordered': () ->
    } 

    before ->
      engine = new GSS
      engine.abstract.UnorderedCommand = UnorderedCommand
      
      engine.compile(true)
    
    describe 'and no required arguments', ->
      it 'should match property function definition', ->
        expect(engine.abstract.Command(['unordered', 'test'])).to.be.an.instanceof(UnorderedCommand.unordered)
        expect(engine.abstract.Command(['unordered', 'test', 10])).to.be.an.instanceof(UnorderedCommand.unordered)
        expect(engine.abstract.Command(['unordered', 'test', 10, 20])).to.be.an.instanceof(UnorderedCommand.unordered)
        expect(engine.abstract.Command(['unordered', 10, 'test', 20])).to.be.an.instanceof(UnorderedCommand.unordered)
        expect(engine.abstract.Command(['unordered', 10, 20, 'test'])).to.be.an.instanceof(UnorderedCommand.unordered)
        expect(engine.abstract.Command(['unordered', 10, 20, 'test', 30])).to.not.be.an.instanceof(UnorderedCommand.unordered)
        expect(engine.abstract.Command(['unordered', 'test', 'test'])).to.not.be.an.instanceof(UnorderedCommand.unordered)

    describe 'with variables', ->
      it 'should match property function definition', ->
        expect(engine.abstract.Command(['unordered', ['get', 'test']])).to.be.an.instanceof(UnorderedCommand.unordered)
        expect(engine.abstract.Command(['unordered', ['get', 'test'], 10])).to.be.an.instanceof(UnorderedCommand.unordered)
        expect(engine.abstract.Command(['unordered', ['get', 'test'], 'test'])).to.not.be.an.instanceof(UnorderedCommand.unordered)
        expect(engine.abstract.Command(['unordered', ['get', 'test'], ['get', 'test']])).to.not.be.an.instanceof(UnorderedCommand.unordered)
        expect(engine.abstract.Command(['undeclared', ['get', 'test'], 10])).to.be.an.instanceof(engine.abstract.Default)
    
    describe 'with expressions', ->
      it 'should match property function definition', ->
        expect(engine.abstract.Command(['unordered', ['+',  ['get', 'test'], 1]])).to.be.an.instanceof(UnorderedCommand.unordered)
        expect(engine.abstract.Command(['unordered', ['+',  ['get', 'test'], 1], 10])).to.be.an.instanceof(UnorderedCommand.unordered)
        expect(engine.abstract.Command(['unordered', ['+',  ['get', 'test'], 1], 'test'])).to.not.be.an.instanceof(UnorderedCommand.unordered)
        expect(engine.abstract.Command(['unordered', ['+',  ['get', 'test'], 1], ['+',  ['get', 'test'], 1]])).to.not.be.an.instanceof(UnorderedCommand.unordered)
        expect(engine.abstract.Command(['undeclared', ['+',  ['get', 'test'], 1], 10])).to.be.an.instanceof(engine.abstract.Default)

  describe 'optional group with order specific type declaration', ->
    before ->
      engine = new GSS
      engine.abstract.FancyTypes = GSS::Command.extend {
        signature: [[
          left: ['String', 'Value']
          right: ['Number', 'String']
          mode: ['Number', 'Value']
        ]]
      }, {
        'fancy': () ->
      } 
      engine.compile(true)


    it 'should respect type order', ->
      expect(engine.abstract.Command(['fancy', 'test']).permutation).to.eql([0])
      expect(engine.abstract.Command(['fancy', 'test', 'test']).permutation).to.eql([0, 1])
      expect(engine.abstract.Command(['fancy', 1]).permutation).to.eql([1])
      expect(engine.abstract.Command(['fancy', 1, 1]).permutation).to.eql([1, 2])
      expect(engine.abstract.Command(['fancy', 1, 'a']).permutation).to.eql([1, 0])
      expect(engine.abstract.Command(['fancy', 1, 'a', 1]).permutation).to.eql([1, 0, 2])
      expect(engine.abstract.Command(['fancy', 1, 'a', 'b']).permutation).to.eql(undefined)
      expect(engine.abstract.Command(['fancy', 'a', 1]).permutation).to.eql([0, 1])
      expect(engine.abstract.Command(['fancy', 'a', 1, 2]).permutation).to.eql([0, 1, 2])

  describe 'optional groups and mixed with optional groups', ->
    OptionalGroupCommand = GSS::Command.extend {
      signature: [
        left: ['Value', 'String']
        [
          a: ['String']
          b: ['Number']
        ]
        right: ['Number']
        [
          c: ['Number']
        ]
      ]
    }, {
      'optional': () ->
    }
  
    before ->
      engine = new GSS
      engine.abstract.OptionalGroupCommand = OptionalGroupCommand
      engine.compile(true)
      
    describe 'and no required arguments', ->
      it 'should match property function definition', ->
        expect(engine.abstract.Command(['optional', 'test'])).to.not.be.an.instanceof(OptionalGroupCommand.optional)
        expect(engine.abstract.Command(['optional', 'test', 10])).to.be.an.instanceof(OptionalGroupCommand.optional)
        expect(engine.abstract.Command(['optional', 'test', 10, 20])).to.be.an.instanceof(OptionalGroupCommand.optional)
        expect(engine.abstract.Command(['optional', 'test', 10, 'test', 20])).to.be.an.instanceof(OptionalGroupCommand.optional)
        expect(engine.abstract.Command(['optional', 'test', 10, 20, 'test'])).to.not.be.an.instanceof(OptionalGroupCommand.optional)
        expect(engine.abstract.Command(['optional', 'test', 10, 'test', 20, 30])).to.be.an.instanceof(OptionalGroupCommand.optional)
        expect(engine.abstract.Command(['optional', 'test', 'test'])).to.not.be.an.instanceof(OptionalGroupCommand.optional)
        expect(engine.abstract.Command(['optional', 'test', 10, 'test', 20, 30]).permutation).to.eql([0,2,1,3,4])
        expect(engine.abstract.Command(['optional', 'test', 10, 'test', 20]).permutation).to.eql([0,2,1,3])
        expect(engine.abstract.Command(['optional', 'test', 10, 20]).permutation).to.eql([0,2,3])

    describe 'with variables', ->
      it 'should match property function definition', ->
        expect(engine.abstract.Command(['optional', ['get', 'test']])).to.not.be.an.instanceof(OptionalGroupCommand.optional)
        expect(engine.abstract.Command(['optional', ['get', 'test'], 10])).to.be.an.instanceof(OptionalGroupCommand.optional)
        expect(engine.abstract.Command(['optional', ['get', 'test'], 'test'])).to.not.be.an.instanceof(OptionalGroupCommand.optional)
        expect(engine.abstract.Command(['optional', ['get', 'test'], ['get', 'test']])).to.not.be.an.instanceof(OptionalGroupCommand.optional)
        expect(engine.abstract.Command(['undeclared', ['get', 'test'], 10])).to.be.an.instanceof(engine.abstract.Default)
    
    describe 'with expressions', ->
      it 'should match property function definition', ->
        expect(engine.abstract.Command(['optional', ['+',  ['get', 'test'], 1]])).to.not.be.an.instanceof(OptionalGroupCommand.optional)
        expect(engine.abstract.Command(['optional', ['+',  ['get', 'test'], 1], 10])).to.be.an.instanceof(OptionalGroupCommand.optional)
        expect(engine.abstract.Command(['optional', ['+',  ['get', 'test'], 1], 'test'])).to.not.be.an.instanceof(OptionalGroupCommand.optional)
        expect(engine.abstract.Command(['optional', ['+',  ['get', 'test'], 1], 'test', 10])).to.be.an.instanceof(OptionalGroupCommand.optional)

describe '', ->
  1


