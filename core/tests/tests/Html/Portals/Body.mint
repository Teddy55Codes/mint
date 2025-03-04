suite "Html.Portals.Body" {
  test "renders single children into the body" {
    <Html.Portals.Body><portal-body/></Html.Portals.Body>
    |> Test.Html.start()
    |> Test.Context.then(
      (subject : Dom.Element) : Promise(Bool) {
        Dom.getElementBySelector("body > portal-body")
        |> Maybe.map((element : Dom.Element) : Bool { true })
        |> Maybe.withDefault(false)
        |> Promise.resolve()
      })
    |> Test.Context.assertEqual(true)
  }

  test "renders multiple children into the body" {
    <Html.Portals.Body>
      <portal-body/>
      <portal-body2/>
    </Html.Portals.Body>
    |> Test.Html.start()
    |> Test.Context.then(
      (subject : Dom.Element) : Promise(Bool) {
        Dom.getElementBySelector("body > portal-body2")
        |> Maybe.map((element : Dom.Element) : Bool { true })
        |> Maybe.withDefault(false)
        |> Promise.resolve()
      })
    |> Test.Context.assertEqual(true)
  }
}
