define [
  'jquery'
  'react'
  'react-router'
  'compiled/react_files/components/BreadcrumbCollapsedContainer'
  'compiled/models/Folder'
  'compiled/react_files/modules/filesEnv'
  '../mockFilesENV'
  '../../helpers/stubRouterContext'
], ($, React, ReactRouter, BreadcrumbCollapsedContainerComponent, Folder, filesEnv, mockFilesENV, stubRouterContext) ->
  simulate = React.addons.TestUtils.Simulate
  simulateNative = React.addons.TestUtils.SimulateNative
  TestUtils = React.addons.TestUtils

  module 'BreadcrumbsCollapsedContainer',
    setup: ->
      folder = new Folder(name: 'Test Folder', urlPath: 'test_url', url: 'stupid')
      folder.url = -> "stupid"
      props = foldersToContain: [folder]

      bcc = stubRouterContext(BreadcrumbCollapsedContainerComponent, props)
      BreadcrumbCollapsedContainer = React.createFactory(bcc)
      @bcc = TestUtils.renderIntoDocument(BreadcrumbCollapsedContainer(props))

    teardown: ->
      React.unmountComponentAtNode(@bcc.getDOMNode().parentNode)

  test 'BCC: opens breadcumbs on mouse enter', ->
    $node = $(@bcc.getDOMNode())
    simulateNative.mouseOver(@bcc.getDOMNode())
    equal $node.find('.open').length, 1, "should have class of open"

  test 'BCC: opens breadcrumbs on focus', ->
    $node = $(@bcc.getDOMNode())
    simulate.focus(@bcc.getDOMNode())
    equal $node.find('.open').length, 1, "should have class of open"

  test 'BCC: closes breadcrumbs on mouse leave', ->
    clock = sinon.useFakeTimers()

    $node = $(@bcc.getDOMNode())
    simulateNative.mouseOut(@bcc.getDOMNode())
    clock.tick(200)
    equal $node.find('.undefined').length, 1, "should have class of undefined"

    clock.restore()

  test 'BCC: closes breadcrumbs on blur', ->
    clock = sinon.useFakeTimers()
    $node = $(@bcc.getDOMNode())
    simulate.blur(@bcc.getDOMNode())
    clock.tick(200)

    equal $node.find('.undefined').length, 1, "should have class of undefined"

    clock.restore()

