Template.TemplateRender.onCreated ->
  @compiledId = new ReactiveVar

Template.TemplateRender.onRendered ->
  # TODO: clean up compiled templates
  @autorun =>
    @compiledId.set compileTemplate(@data.id)

Template.TemplateRender.helpers
  compiledId: ->
    {compiledId} = Template.instance()
    compiledId.get()
