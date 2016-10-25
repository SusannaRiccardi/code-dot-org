Feature: Text To Speech

# Fully skip, seeing intermittent failures on IE, Safari, possibly others on CircleCI
@skip
Scenario: Listen to TTS Audio
  Given I am on "http://studio.code.org/s/course1/stage/4/puzzle/1?noautoplay=true&enableExperiments=topInstructionsCSF&enableExperiments=tts"
  And I rotate to landscape

  Then element "#tts-button" is visible

  When I press "tts-button"
  And I wait until element "audio" is visible

  Then element "#alert-content" does not exist

Scenario: Listen to TTS Audio
  Given I am on "http://studio.code.org/s/allthethings/stage/6/puzzle/3?noautoplay=true&enableExperiments=topInstructionsCSF&enableExperiments=tts"
  And I rotate to landscape

  # note: we expect no audio for the instructions, because this test
  # level is not in course1.
  Then element ".csf-top-instructions .inline-audio" does not exist

  # running with default setup should give me a feedback audio and a
  # block hint audio
  When I press "runButton"
  And I wait to see ".uitest-topInstructions-inline-feedback"
  And I resize top instructions to 500 pixels tall
  Then I see 2 of ".csf-top-instructions .inline-audio"
  Then I listen to the entirety of the "0"th inline audio element
  Then I listen to the entirety of the "1"th inline audio element

  # requesting a hint should give me another
  When I press "lightbulb"
  Then I see 3 of ".csf-top-instructions .inline-audio"
  And I resize top instructions to 500 pixels tall
  Then I listen to the entirety of the "2"th inline audio element

  # viewing the hint should give me another, while removing the hint
  # request dialog and the feedback.
  When I press ".csf-top-instructions button:contains('Yes')" using jQuery
  And I wait to see ".block-space"
  And I resize top instructions to 500 pixels tall
  Then I see 2 of ".csf-top-instructions .inline-audio"
  Then I listen to the entirety of the "1"th inline audio element
