import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import funkin.play.PlayState;
import funkin.play.PlayStatePlaylist;
import funkin.play.song.Song;
import flixel.util.FlxTimer;
import funkin.save.Save;
import funkin.audio.FunkinSound;
import funkin.data.song.SongRegistry;
import funkin.modding.base.ScriptedFlxAtlasSprite;
import flixel.FlxG;
import funkin.util.HapticUtil;
import funkin.Highscore;
import funkin.modding.module.Module;
import flixel.text.FlxText;
import funkin.Highscore;
import funkin.play.PlayState;
import funkin.Paths;
import funkin.ui.options.OptionsState;
import flixel.tweens.FlxTween;
import funkin.modding.module.ModuleHandler;
import funkin.util.MathUtil;
import funkin.ui.options.PreferencesMenu;
import flixel.ui.FlxBarFillDirection;
import funkin.util.Constants;
import flixel.text.FlxTextBorderStyle;
import funkin.save.Save;
import funkin.play.scoring.Scoring;
import flixel.text.FlxTextFormatMarkerPair;
import flixel.text.FlxTextFormat;
import funkin.Conductor;
import funkin.Preferences;
import flixel.math.FlxMath;
import flixel.ui.FlxBar;
import flixel.FlxSprite;
import flixel.FlxG;
import funkin.Conductor;
import funkin.play.character.CharacterType;
import funkin.data.character.CharacterDataParser;

class Blissful2021SongScript extends Song
{
  public function new()
  {
    super('blissful-2021');
  }

  var scoreTxt:FlxText;
  var judgementCounter:FlxText;
  var loadedGame = true;
  var onClassic:Bool = false;
  var totalNotesHit:Float = 0.00;
  var totalNotesPlayed:Int = 0;
  var options:Array<Dynamic> = [];
  var settings:Dynamic = {
    enableHud: true,
    msDisplay: true,
    highResolutionText: true,
    timeBar: true,
    baseGameRank: false,
    baseGameAccuracy: false,
    accurateComboBreaks: true,
    npsDisplay: true,
    lerpEverything: false,
    centerText: false,
    judgementCounter: false,
    disableKeWatermark: false
  };

  var ps;
  var msDisplayText:FlxText; // its one text object cuz spawning a billion objects is gay
  var scoreLerp:Int = 0;
  var accuracyLerp:Float = 0;

  var up = 0;

  function onUpdate(e)
  {
    up += e;
    if (up >= .25)
    {
      up = 0;
      return;
    }

    if (loadedGame && settings.enableHud && Conductor.instance.songPosition > 0)
    {
      if (scoreTxt != null)
      {
        scoreTxt.applyMarkup(generateScoreString(),
          [new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFFFF00),
            '/y/'), new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFFFF66),
              '/yw/'), new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFF00FF),
              '/p/'), new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFFAA00), '/o/'), new FlxTextFormatMarkerPair(new FlxTextFormat(0xFF0000FF), '/b/'),]);
        if (!settings.centerText)
        {
          var lengthInPx = scoreTxt.textField.length * scoreTxt.frameHeight; // bad way but does more or less a better job
          scoreTxt.x = (originalX - (lengthInPx / (2 * upscaleMult))) + 135;
        }
      }

      scoreLerp = Std.int(FlxMath.lerp(scoreLerp, ps.songScore, 0.2 - e.elapsed));
      accuracyLerp = FlxMath.lerp(accuracyLerp, getAccuracy(), 0.2 - e.elapsed);
      if (FlxG.sound.music != null) songPercent.value = FlxG.sound.music.time / FlxG.sound.music.length;

      var balls = notesHitArray.length - 1;
      while (balls >= 0)
      {
        var cock:Date = notesHitArray[balls];
        if (cock != null && cock + 1000 < Conductor.instance.songPosition) notesHitArray.remove(cock);
        else
          balls = 0;
        balls--;
      }
      nps = notesHitArray.length;
      if (nps > maxNPS) maxNPS = nps;
    }
  }

  function upscaleText(textObject)
  {
    // textObject.fieldWidth *= upscaleMult;
    // textObject.size *= upscaleMult;
    // textObject.borderSize *= upscaleMult;
    // textObject.scale.set(1/upscaleMult,1/upscaleMult);
    // textObject.antialiasing = true;
    // textObject.updateHitbox();
    return;
  }

  function onNoteHit(event)
  {
    if (event.judgement != "perfect")
    {
      var noteDiff = Math.abs(Conductor.instance.songPosition - event.note.noteData.time);
      var addShit = 35 / noteDiff;

      totalNotesHit += (addShit > 1 ? 1 : addShit);
      totalNotesPlayed++;
      prevCombo = event.comboCount;
      notesHitArray.unshift(event.note.noteData.time);
      if (settings.msDisplay && settings.enableHud)
      {
        makeMsDisplay(Conductor.instance.songPosition - event.note.noteData.time, event.judgement);
      }
    }
    super.onNoteHit(event);
  }

  function getAccuracy()
  {
    var accuracy = Math.max(0, totalNotesHit / totalNotesPlayed * 100);
    if (settings.baseGameAccuracy)
    {
      accuracy = (Highscore.tallies.sick + Highscore.tallies.good) / (Highscore.tallies.totalNotesHit + Highscore.tallies.missed) * 100;
    }
    if (!Math.isFinite(accuracy)) return 0;
    return accuracy;
  }

  var msTween:FlxTween;

  function makeMsDisplay(differenceRaw, judgement)
  {
    if (msDisplayText != null)
    {
      PlayState.instance.remove(msDisplayText);
      msDisplayText.destroy();
      msTween.cancel();
    }
    msDisplayText = new FlxText(0, 0, 0, "", 20);
    if (settings.baseGameAccuracy)
    {
      switch (judgement)
      {
        case 'shit' | 'bad':
          msDisplayText.color = 0xFFFF0000;
        case 'good':
          msDisplayText.color = 0xFFFF00FF;
        case 'sick':
          msDisplayText.color = 0xFFFFFF00;
      }
    }
    else
    {
      switch (judgement)
      {
        case 'shit' | 'bad':
          msDisplayText.color = 0xFFFF0000;
        case 'good':
          msDisplayText.color = 0xFF00FF00;
        case 'sick':
          msDisplayText.color = 0xFF00FFFF;
      }
    }
    msDisplayText.borderStyle = FlxTextBorderStyle.OUTLINE;
    msDisplayText.borderSize = 1;
    msDisplayText.borderColor = 0xFF000000;
    msDisplayText.size = 20;
    msDisplayText.text = truncateFloat(differenceRaw, 2) + "ms";
    msDisplayText.x = (FlxG.width * 0.507) + 100;
    msDisplayText.y = (FlxG.height * 0.45 - 60) + 100;
    upscaleText(msDisplayText);
    PlayState.instance.add(msDisplayText);
    msDisplayText.cameras = [PlayState.instance.camHUD];
    msDisplayText.alpha = 1;
    msTween = FlxTween.tween(msDisplayText, {alpha: 0}, 0.2, {
      onComplete: function(tween:FlxTween)
      {
        msDisplayText.destroy();
      },
      startDelay: 0.1
    });
  }

  function getBaseRank()
  {
    var grade = (Highscore.tallies.sick + Highscore.tallies.good) / (Highscore.tallies.totalNotesHit + Highscore.tallies.missed);
    if (Highscore.tallies.sick == Highscore.tallies.totalNotesHit)
    {
      return '/y/P/y/'; // Gold P
    }
    else
    {
      var wifeConditions:Array<Bool> = [grade >= 1, // Purple P
        grade >= Constants.RANK_EXCELLENT_THRESHOLD, // E
        grade >= Constants.RANK_GREAT_THRESHOLD, // WHITE G
        grade >= Constants.RANK_GOOD_THRESHOLD, // ORANGE G
        true // L
      ];
      for (i in 0...wifeConditions.length)
      {
        var b = wifeConditions[i];
        if (b)
        {
          switch (i)
          {
            case 0:
              return '/p/P/p/';
            case 1:
              return '/yw/E/yw/';
            case 2:
              return 'G';
            case 3:
              return '/o/G/o/';
            case 4:
              return '/b/L/b/';
          }
        }
      }
    }
  }

  function generateRanking():String
  {
    var ranking:String = "N/A";
    var misses = Highscore.tallies.missed;
    var bads = Highscore.tallies.bad;
    var shits = Highscore.tallies.shit;
    var goods = Highscore.tallies.good;
    var accuracy = getAccuracy();

    if (settings.baseGameRank)
    {
      ranking = getBaseRank(accuracy);
    }
    else
    {
      if (misses == 0 && bads == 0 && shits == 0 && goods == 0) // Marvelous (SICK) Full Combo
        ranking = "(MFC)";
      else if (misses == 0 && bads == 0 && shits == 0 && goods >= 1) // Good Full Combo (Nothing but Goods & Sicks)
        ranking = "(GFC)";
      else if (misses == 0) // Regular FC
        ranking = "(GFC)";
      else if (misses < 10) // Single Digit Combo Breaks
        ranking = "(SDCB)";
      else
        ranking = "(Clear)";
      // WIFE TIME :)))) (based on Wife3)
      // kade what do you mean by wife only women can be lesbians
      var wifeConditions:Array<Bool> = [accuracy >= 99.9935, // AAAAA
        accuracy >= 99.980, // AAAA:
        accuracy >= 99.970, // AAAA.
        accuracy >= 99.955, // AAAA
        accuracy >= 99.90, // AAA:
        accuracy >= 99.80, // AAA.
        accuracy >= 99.70, // AAA
        accuracy >= 99, // AA:
        accuracy >= 96.50, // AA.
        accuracy >= 93, // AA
        accuracy >= 90, // A:
        accuracy >= 85, // A.
        accuracy >= 80, // A
        accuracy >= 70, // B
        accuracy >= 60, // C
        accuracy < 60 // D
      ];

      for (i in 0...wifeConditions.length)
      {
        var b = wifeConditions[i];
        if (b)
        {
          switch (i)
          {
            case 0:
              ranking += " AAAAA";
            case 1:
              ranking += " AAAA:";
            case 2:
              ranking += " AAAA.";
            case 3:
              ranking += " AAAA";
            case 4:
              ranking += " AAA:";
            case 5:
              ranking += " AAA.";
            case 6:
              ranking += " AAA";
            case 7:
              ranking += " AA:";
            case 8:
              ranking += " AA.";
            case 9:
              ranking += " AA";
            case 10:
              ranking += " A:";
            case 11:
              ranking += " A.";
            case 12:
              ranking += " A";
            case 13:
              ranking += " B";
            case 14:
              ranking += " C";
            case 15:
              ranking += " D";
          }
          break;
        }
      }
    }

    if (accuracy == 0) ranking = "N/A";

    return ranking;
  }

  override function onNoteMiss(event)
  {
    super.onNoteMiss(event);
    totalNotesPlayed++;
  }

  override function onSongRetry(event)
  {
    super.onSongRetry(event);
    trace("asdasd");
    totalNotesHit = 0.00;
    totalNotesPlayed = 0;
    notesHitArray = [];
    nps = 0;
    maxNPS = 0;

    var oldDAD = PlayState.instance.currentStage.getDad(true);
    oldZIndex = oldDAD.zIndex;
    oldDAD.destroy();

    var dad = CharacterDataParser.fetchCharacter("qt-legacy");
    if (dad != null)
    {
      dad.characterType = CharacterType.DAD;
      PlayState.instance.currentStage.addCharacter(dad, CharacterType.DAD);
      dad.zIndex = oldZIndex + 500;
    }
  }

  var songPosBG:FlxSprite;
  var songPosBar:FlxBar;
  var songPercent = {
    value: 0
  };
  var songNameText:FlxText;
  var originalX:Float = 0;
  var notesHitArray:Array<Float> = [];
  var nps:Int = 0;
  var maxNPS:Int = 0;

  function truncateFloat(number:Float, precision:Int):Float
  {
    var num = number;
    num = num * Math.pow(10, precision);
    num = Math.round(num) / Math.pow(10, precision);
    return num;
  }

  var upscaleMult:Float = 1;
  var createdHud = false;

  override function onCountdownStart(event)
  {
    if (settings.highResolutionText)
    {
      upscaleMult = 2;
    }

    super.onCountdownStart(event);
  }

  override function onCreate(e)
  {
    super.onCreate(e);
    ps = PlayState.instance;
    totalNotesHit = 0.00;
    totalNotesPlayed = 0;
    var dad = CharacterDataParser.fetchCharacter("qt-legacy");
    createHud();
  }

  function generateScoreString()
  {
    var score = Math.floor(PlayState.instance.songScore);
    var misses = Highscore.tallies.missed;
    var accuracy = getAccuracy();
    if (settings.accurateComboBreaks)
    {
      misses += Highscore.tallies.bad + Highscore.tallies.shit;
    }
    if (settings.lerpEverything)
    {
      score = scoreLerp;
      accuracy = accuracyLerp;
    }
    var textString = (settings.npsDisplay ? "NPS: " + nps + " (Max " + maxNPS + ') | ' : '');
    textString += 'Score: ' + score;
    textString += " | Combo Breaks:" + misses;
    textString += " | Accuracy:" + truncateFloat(accuracy, 2);
    textString += "% | " + generateRanking();
    if (judgementCounter != null) judgementCounter.text = 'Sicks: ' + Highscore.tallies.sick + '\nGoods: ' + Highscore.tallies.good + '\nBads: '
      + Highscore.tallies.bad + '\nShits: ' + Highscore.tallies.shit + '\nMisses: ' + Highscore.tallies.missed;
    return textString;
  }

  function createHud()
  {
    createdHud = true;
    // hud stuff here
    var ps = PlayState.instance;
    notesHitArray = [];
    nps = 0;
    maxNPS = 0;
    if (!settings.disableKeWatermark)
    {
      var kadeEngineWatermark = new FlxText(4, ps.healthBarBG.y + 50, 1280, ps.get_currentChart().songName + " - KE 1.4.2", 16);
      kadeEngineWatermark.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFFFFF, 'left', FlxTextBorderStyle.OUTLINE, 0xFF000000);
      kadeEngineWatermark.scrollFactor.set(0, 0);
      ps.add(kadeEngineWatermark);
      kadeEngineWatermark.cameras = [ps.camHUD];
      upscaleText(kadeEngineWatermark);
      if (Preferences.downscroll) kadeEngineWatermark.y = FlxG.height * 0.9 + 45;
    }
    ps.scoreText.visible = false;

    scoreTxt = new FlxText(FlxG.width / 2 - 235, ps.healthBarBG.y + 50, 1280, generateScoreString(), 20);
    scoreTxt.x = ps.healthBarBG.x + ps.healthBarBG.width / 2;
    scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFFFFF, 'left', FlxTextBorderStyle.OUTLINE, 0xFF000000);
    scoreTxt.scrollFactor.set();
    ps.add(scoreTxt);
    upscaleText(scoreTxt);
    originalX = scoreTxt.x;
    if (settings.centerText)
    {
      scoreTxt.alignment = 'center';
      scoreTxt.x = 0;
    }

    if (settings.judgementCounter && judgementCounter == null)
    {
      judgementCounter = new FlxText(-20, 0, 1280, "", 20);
      judgementCounter.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFFFFF, 'right', FlxTextBorderStyle.OUTLINE, 0xFF000000);
      judgementCounter.borderSize = 1;
      judgementCounter.scrollFactor.set();
      judgementCounter.cameras = [ps.camHUD];
      upscaleText(judgementCounter);
      ps.add(judgementCounter);
      judgementCounter.screenCenter(0x10);
    }
    if (settings.timeBar)
    {
      songPosBG = new FlxSprite(0, 10).loadGraphic(Paths.image('healthBar'));
      if (Preferences.downscroll) songPosBG.y = FlxG.height * 0.9 + 45;
      songPosBG.screenCenter(0x01);
      songPosBG.scrollFactor.set();
      ps.add(songPosBG);

      songPosBar = new FlxBar(songPosBG.x + 4, songPosBG.y + 4, FlxBarFillDirection.LEFT_TO_RIGHT, Std.int(songPosBG.width - 8),
        Std.int(songPosBG.height - 8), songPercent, 'value', 0, 1);
      songPosBar.numDivisions = 10000;
      songPosBar.scrollFactor.set();
      songPosBar.createFilledBar(0xFF999999, 0xFF00FF00);
      ps.add(songPosBar);

      var songName = new FlxText(songPosBG.x, songPosBG.y, songPosBG.width, ps.get_currentChart().songName, songPosBG.height);
      songName.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFFFFF, 'center', FlxTextBorderStyle.OUTLINE, 0xFF000000);
      songName.scrollFactor.set();
      ps.add(songName);
      upscaleText(songName);
      songPosBG.cameras = [ps.camHUD];
      songPosBar.cameras = [ps.camHUD];
      songName.cameras = [ps.camHUD];
    }

    ps.playerStrumline.noteHoldCovers.alpha = settings.holdSplashes ? 0 : 1;
    ps.opponentStrumline.noteHoldCovers.alpha = settings.holdSplashes ? 0 : 1;
    ps.playerStrumline.noteSplashes.alpha = settings.noteSplashes ? 0 : 1;
    ps.opponentStrumline.noteSplashes.alpha = settings.noteSplashes ? 0 : 1;

    scoreTxt.cameras = [ps.camHUD];
  }

  function onBeatHit(e)
  {
    if (e.beat == 287)
    {
      var oldDAD = PlayState.instance.currentStage.getDad(true);
      oldZIndex = oldDAD.zIndex;
      oldDAD.destroy();

      var dad = CharacterDataParser.fetchCharacter("qt-kb-legacy");
      if (dad != null)
      {
        dad.characterType = CharacterType.DAD;
        PlayState.instance.currentStage.addCharacter(dad, CharacterType.DAD);
        dad.zIndex = oldZIndex + 500;
      }
    }
  }
}
