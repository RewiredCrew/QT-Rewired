import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import funkin.play.PlayState;
import funkin.play.song.Song;
import funkin.Highscore;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.text.FlxTextFormatMarkerPair;
import flixel.text.FlxTextFormat;
import funkin.Conductor;
import funkin.Preferences;
import flixel.math.FlxMath;
import flixel.FlxG;
import funkin.Paths;
import funkin.util.Constants;
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
  var msDisplayText:FlxText;
  var msTween:FlxTween;
  
  var loadedGame = true;
  var totalNotesHit:Float = 0.00;
  var totalNotesPlayed:Int = 0;
  var nps:Int = 0;
  var maxNPS:Int = 0;
  var notesHitArray:Array<Float> = [];

  var scoreLerp:Int = 0;
  var accuracyLerp:Float = 0;

  var ps:PlayState;
  var dadKB:Dynamic;
  var markupPairs:Array<FlxTextFormatMarkerPair>;
  var nextLagTime:Float = 0;

  var settings:Dynamic = {
    enableHud: true,
    msDisplay: true,
    highResolutionText: true,
    baseGameRank: false,
    baseGameAccuracy: false,
    accurateComboBreaks: true,
    npsDisplay: true,
    lerpEverything: false,
    judgementCounter: false,
    disableKeWatermark: false,
    holdSplashes: false,
    noteSplashes: false
  };
  var currentPos:Dynamic;

  override function onCreate(e)
  {
    super.onCreate(e);
    ps = PlayState.instance;
    totalNotesHit = 0.00;
    totalNotesPlayed = 0;
    markupPairs = [
      new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFFFF00), '/y/'),
      new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFFFF66), '/yw/'),
      new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFF00FF), '/p/'),
      new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFFAA00), '/o/'),
      new FlxTextFormatMarkerPair(new FlxTextFormat(0xFF0000FF), '/b/')
    ];

    dadKB = CharacterDataParser.fetchCharacter("qt-kb-legacy");

    setupHUDPositions();
    scheduleNextLag();
    createHud();
  }

  function setupHUDPositions()
  {
    var isAltMode:Bool = Preferences.downscroll || FlxG.onMobile;
    
    if (isAltMode) 
    {
      currentPos = { 
        scoreX: 0, 
        scoreY: FlxG.height * 0.17, 
        fieldWidth: FlxG.width, 
        align: 'center' 
      };
    } 
    else 
    {
      var upscrollOffsetX:Float = FlxG.width * 0.35; 
      currentPos = { 
        scoreX: upscrollOffsetX, 
        scoreY: ps.healthBarBG.y + 50, 
        fieldWidth: 0, 
        align: 'left' 
      };
    }
  }
  function onUpdate(e)
  {
    if (!loadedGame || !settings.enableHud) return;

    if (Conductor.instance.songPosition > 0)
    {
        handleFakeLag();
    }

    if (scoreTxt != null)
    {
      scoreTxt.applyMarkup(generateScoreString(), markupPairs);
    }

    scoreLerp = Std.int(FlxMath.lerp(scoreLerp, ps.songScore, 0.2 - e.elapsed));
    accuracyLerp = FlxMath.lerp(accuracyLerp, getAccuracy(), 0.2 - e.elapsed);

    var currentTime = Conductor.instance.songPosition;
    while (notesHitArray.length > 0 && notesHitArray[notesHitArray.length - 1] + 1000 < currentTime)
    {
      notesHitArray.pop();
    }
    
    nps = notesHitArray.length;
    if (nps > maxNPS) maxNPS = nps;
  }

  // lag !!!
  function scheduleNextLag()
  {
    nextLagTime = Conductor.instance.songPosition + FlxG.random.float(1500, 6000);
  }

  function handleFakeLag()
  {
    if (Conductor.instance.songPosition >= nextLagTime)
    {
      var isHeavyLag:Bool = FlxG.random.bool(25);
      var iterations:Int = isHeavyLag ? FlxG.random.int(100000, 250000) : FlxG.random.int(15000, 40000);

      var trash:Float = 0;
      for (i in 0...iterations) 
      {
        trash = Math.sin(i) * Math.cos(i);
      }
      scheduleNextLag();
    }
  }
  function onNoteHit(event)
  {
    super.onNoteHit(event);
    
    if (event.judgement != "perfect")
    {
      var noteDiff = Math.abs(Conductor.instance.songPosition - event.note.noteData.time);
      var addShit = 35 / noteDiff;

      totalNotesHit += (addShit > 1 ? 1 : addShit);
      totalNotesPlayed++;
      
      notesHitArray.unshift(event.note.noteData.time);
      
      if (settings.msDisplay && settings.enableHud)
      {
        makeMsDisplay(Conductor.instance.songPosition - event.note.noteData.time, event.judgement);
      }
    }
  }

  function makeMsDisplay(differenceRaw:Float, judgement:String)
  {
    if (msDisplayText == null)
    {
      msDisplayText = new FlxText(0, 0, 0, "", 16); 
      msDisplayText.borderStyle = FlxTextBorderStyle.OUTLINE;
      msDisplayText.borderSize = 1;
      msDisplayText.borderColor = 0xFF000000;
      
      msDisplayText.x = (FlxG.width * 0.507) + 100;
      msDisplayText.y = (FlxG.height * 0.45 - 60) + 100;
      
      msDisplayText.cameras = [ps.camHUD];
      ps.add(msDisplayText);
    }

    if (msTween != null) msTween.cancel();

    var colorCode = 0xFFFFFFFF;
    if (settings.baseGameAccuracy)
    {
      switch (judgement)
      {
        case 'shit' | 'bad': colorCode = 0xFFFF0000;
        case 'good': colorCode = 0xFFFF00FF;
        case 'sick': colorCode = 0xFFFFFF00;
      }
    }
    else
    {
      switch (judgement)
      {
        case 'shit' | 'bad': colorCode = 0xFFFF0000;
        case 'good': colorCode = 0xFF00FF00;
        case 'sick': colorCode = 0xFF00FFFF;
      }
    }

    msDisplayText.color = colorCode;
    msDisplayText.text = truncateFloat(differenceRaw, 2) + "ms";
    msDisplayText.alpha = 1;
    
    msTween = FlxTween.tween(msDisplayText, {alpha: 0}, 0.2, {startDelay: 0.1});
  }

  function getAccuracy():Float
  {
    var accuracy = Math.max(0, totalNotesHit / totalNotesPlayed * 100);
    if (settings.baseGameAccuracy)
    {
      accuracy = (Highscore.tallies.sick + Highscore.tallies.good) / (Highscore.tallies.totalNotesHit + Highscore.tallies.missed) * 100;
    }
    if (!Math.isFinite(accuracy)) return 0;
    return accuracy;
  }

  function truncateFloat(number:Float, precision:Int):Float
  {
    var num = number * Math.pow(10, precision);
    return Math.round(num) / Math.pow(10, precision);
  }

  function getBaseRank():String
  {
    var grade = (Highscore.tallies.sick + Highscore.tallies.good) / (Highscore.tallies.totalNotesHit + Highscore.tallies.missed);
    if (Highscore.tallies.sick == Highscore.tallies.totalNotesHit) return '/y/P/y/';
    
    if (grade >= 1) return '/p/P/p/';
    if (grade >= Constants.RANK_EXCELLENT_THRESHOLD) return '/yw/E/yw/';
    if (grade >= Constants.RANK_GREAT_THRESHOLD) return 'G';
    if (grade >= Constants.RANK_GOOD_THRESHOLD) return '/o/G/o/';
    return '/b/L/b/';
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
      ranking = getBaseRank();
    }
    else
    {
      if (misses == 0 && bads == 0 && shits == 0 && goods == 0) ranking = "(MFC)";
      else if (misses == 0 && bads == 0 && shits == 0 && goods >= 1) ranking = "(GFC)";
      else if (misses == 0) ranking = "(GFC)";
      else if (misses < 10) ranking = "(SDCB)";
      else ranking = "(Clear)";

      if (accuracy >= 99.9935) ranking += " AAAAA.";
      else if (accuracy >= 99.980) ranking += " AAAA.";
      else if (accuracy >= 99.970) ranking += " AAAA.";
      else if (accuracy >= 99.955) ranking += " AAAA.";
      else if (accuracy >= 99.90) ranking += " AAA.";
      else if (accuracy >= 99.80) ranking += " AAA.";
      else if (accuracy >= 99.70) ranking += " AAA.";
      else if (accuracy >= 99) ranking += " AA.";
      else if (accuracy >= 96.50) ranking += " AA.";
      else if (accuracy >= 93) ranking += " AA.";
      else if (accuracy >= 90) ranking += " A.";
      else if (accuracy >= 85) ranking += " A.";
      else if (accuracy >= 80) ranking += " A.";
      else if (accuracy >= 70) ranking += " B.";
      else if (accuracy >= 60) ranking += " C.";
      else ranking += " D.";
    }

    if (accuracy == 0) ranking = "N/A";
    return ranking;
  }

  function generateScoreString():String
  {
    var score = Math.floor(ps.songScore);
    var misses = Highscore.tallies.missed;
    var accuracy = getAccuracy();
    
    if (settings.accurateComboBreaks) misses += Highscore.tallies.bad + Highscore.tallies.shit;
    if (settings.lerpEverything)
    {
      score = scoreLerp;
      accuracy = accuracyLerp;
    }
    
    var textString = (settings.npsDisplay ? "NPS: " + nps + ' | ' : '');
    textString += 'Score: ' + score + " | Combo Breaks:" + misses + " | Accuracy:" + truncateFloat(accuracy, 2) + "% | " + generateRanking();
    
    if (judgementCounter != null) 
    {
      judgementCounter.text = 'Sicks: ' + Highscore.tallies.sick + '\nGoods: ' + Highscore.tallies.good + '\nBads: '
        + Highscore.tallies.bad + '\nShits: ' + Highscore.tallies.shit + '\nMisses: ' + Highscore.tallies.missed;
    }
    return textString;
  }

  function createHud()
  {
    notesHitArray = [];
    nps = 0;
    maxNPS = 0;
    
    if (!settings.disableKeWatermark)
    {
      var diffRaw:String = (ps.currentDifficulty != null) ? ps.currentDifficulty : "Normal";
      var diffFormated:String = diffRaw.charAt(0).toUpperCase() + diffRaw.substr(1).toLowerCase();
      var watermarkTextContent:String = ps.get_currentChart().songName + " " + diffFormated + " - KE 1.4.2";

      var kadeEngineWatermark = new FlxText(4, 0, 0, watermarkTextContent, 16);
      kadeEngineWatermark.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFFFFF, 'left', FlxTextBorderStyle.OUTLINE, 0xFF000000);
      kadeEngineWatermark.y = FlxG.height - kadeEngineWatermark.height - 4;
      kadeEngineWatermark.scrollFactor.set(0, 0);
      ps.add(kadeEngineWatermark);
      kadeEngineWatermark.cameras = [ps.camHUD];
    }
    
    ps.scoreText.visible = false;
    scoreTxt = new FlxText(currentPos.scoreX, currentPos.scoreY, currentPos.fieldWidth, generateScoreString(), 16);
    scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFFFFF, currentPos.align, FlxTextBorderStyle.OUTLINE, 0xFF000000);
    scoreTxt.scrollFactor.set();
    ps.add(scoreTxt);

    if (settings.judgementCounter)
    {
      judgementCounter = new FlxText(-20, FlxG.height / 2, 1280, "", 14);
      judgementCounter.setFormat(Paths.font("vcr.ttf"), 14, 0xFFFFFFFF, 'right', FlxTextBorderStyle.OUTLINE, 0xFF000000);
      judgementCounter.borderSize = 1;
      judgementCounter.scrollFactor.set();
      judgementCounter.cameras = [ps.camHUD];
      ps.add(judgementCounter);
      judgementCounter.y -= judgementCounter.height / 2; 
    }

    ps.playerStrumline.noteHoldCovers.alpha = settings.holdSplashes ? 0 : 1;
    ps.opponentStrumline.noteHoldCovers.alpha = settings.holdSplashes ? 0 : 1;
    ps.playerStrumline.noteSplashes.alpha = settings.noteSplashes ? 0 : 1;
    ps.opponentStrumline.noteSplashes.alpha = settings.noteSplashes ? 0 : 1;

    scoreTxt.cameras = [ps.camHUD];
  }

  override function onNoteMiss(event)
  {
    super.onNoteMiss(event);
    totalNotesPlayed++;
  }

  override function onSongRetry(event)
  {
    super.onSongRetry(event);
    totalNotesHit = 0.00;
    totalNotesPlayed = 0;
    notesHitArray = [];
    nps = 0;
    maxNPS = 0;
    
    scoreLerp = 0;
    accuracyLerp = 0;

    if (scoreTxt != null) {
      scoreTxt.applyMarkup(generateScoreString(), markupPairs);
    }
    if (judgementCounter != null) {
      judgementCounter.text = 'Sicks: 0\nGoods: 0\nBads: 0\nShits: 0\nMisses: 0';
    }

    var oldDAD = ps.currentStage.getDad(true);
    var oldZIndex = (oldDAD != null) ? oldDAD.zIndex : 0;
    if (oldDAD != null) oldDAD.destroy();

    var dad = CharacterDataParser.fetchCharacter("qt-legacy");
    if (dad != null)
    {
      dad.characterType = CharacterType.DAD;
      ps.currentStage.addCharacter(dad, CharacterType.DAD);
      dad.zIndex = oldZIndex + 500;
    }

    if (dadKB != null) dadKB.destroy();
    dadKB = CharacterDataParser.fetchCharacter("qt-kb-legacy");
  }

  function onBeatHit(e)
  {
    if (e.beat == 287)
    {
      var oldDAD = ps.currentStage.getDad(true);
      var oldZIndex = (oldDAD != null) ? oldDAD.zIndex : 0;
      if (oldDAD != null) oldDAD.destroy();

      if (dadKB != null)
      {
        dadKB.characterType = CharacterType.DAD;
        ps.currentStage.addCharacter(dadKB, CharacterType.DAD);
        dadKB.zIndex = oldZIndex + 500;
        
        dadKB = null; 
      }
    }
  }
}