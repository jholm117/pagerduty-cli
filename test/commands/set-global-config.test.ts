import {expect, test} from '@oclif/test'

const globalAny: any = global

describe('hooks', () => {
  test
  .hook('init', {id: 'set-global-config'})
  .it('sets global.config on init', () => {
    expect(globalAny.config).to.be.ok
    expect(globalAny.config).to.have.property('root')
  })
})
