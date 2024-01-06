package funkin.ui.debug.charting.handlers;

import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.system.FlxSound;
import funkin.audio.VoicesGroup;
import funkin.audio.visualize.PolygonVisGroup;
import funkin.audio.FunkinSound;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.util.FileUtil;
import funkin.util.assets.SoundUtil;
import haxe.io.Bytes;
import haxe.io.Path;
import openfl.utils.Assets;

/**
 * Functions for loading audio for the chart editor.
 * Handlers split up the functionality of the Chart Editor into different classes based on focus to limit the amount of code in each class.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorAudioHandler
{
  /**
   * Loads and stores byte data for a vocal track from an absolute file path
   *
   * @param path The absolute path to the audio file.
   * @param charId The character this vocal track will be for.
   * @param instId The instrumental this vocal track will be for.
   * @return Success or failure.
   */
  public static function loadVocalsFromPath(state:ChartEditorState, path:Path, charId:String, instId:String = '', wipeFirst:Bool = false):Bool
  {
    #if sys
    var fileBytes:Bytes = sys.io.File.getBytes(path.toString());
    return loadVocalsFromBytes(state, fileBytes, charId, instId, wipeFirst);
    #else
    trace("[WARN] This platform can't load audio from a file path, you'll need to fetch the bytes some other way.");
    return false;
    #end
  }

  /**
   * Loads and stores byte data for a vocal track from an asset
   *
   * @param path The path to the asset. Use `Paths` to build this.
   * @param charId The character this vocal track will be for.
   * @param instId The instrumental this vocal track will be for.
   * @return Success or failure.
   */
  public static function loadVocalsFromAsset(state:ChartEditorState, path:String, charId:String, instId:String = '', wipeFirst:Bool = false):Bool
  {
    var trackData:Null<Bytes> = Assets.getBytes(path);
    if (trackData != null)
    {
      return loadVocalsFromBytes(state, trackData, charId, instId, wipeFirst);
    }
    return false;
  }

  /**
   * Loads and stores byte data for a vocal track
   *
   * @param bytes The audio byte data.
   * @param charId The character this vocal track will be for.
   * @param instId The instrumental this vocal track will be for.
   * @param wipeFirst Whether to wipe the existing vocal data before loading.
   */
  public static function loadVocalsFromBytes(state:ChartEditorState, bytes:Bytes, charId:String, instId:String = '', wipeFirst:Bool = false):Bool
  {
    var trackId:String = '${charId}${instId == '' ? '' : '-${instId}'}';
    if (wipeFirst) wipeVocalData(state);
    state.audioVocalTrackData.set(trackId, bytes);
    return true;
  }

  /**
   * Loads and stores byte data for an instrumental track from an absolute file path
   *
   * @param path The absolute path to the audio file.
   * @param instId The instrumental this vocal track will be for.
   * @return Success or failure.
   */
  public static function loadInstFromPath(state:ChartEditorState, path:Path, instId:String = '', wipeFirst:Bool = false):Bool
  {
    #if sys
    var fileBytes:Bytes = sys.io.File.getBytes(path.toString());
    return loadInstFromBytes(state, fileBytes, instId, wipeFirst);
    #else
    trace("[WARN] This platform can't load audio from a file path, you'll need to fetch the bytes some other way.");
    return false;
    #end
  }

  /**
   * Loads and stores byte data for an instrumental track from an asset
   *
   * @param path The path to the asset. Use `Paths` to build this.
   * @param instId The instrumental this vocal track will be for.
   * @return Success or failure.
   */
  public static function loadInstFromAsset(state:ChartEditorState, path:String, instId:String = '', wipeFirst:Bool = false):Bool
  {
    var trackData:Null<Bytes> = Assets.getBytes(path);
    if (trackData != null)
    {
      return loadInstFromBytes(state, trackData, instId, wipeFirst);
    }
    return false;
  }

  /**
   * Loads and stores byte data for a vocal track
   *
   * @param bytes The audio byte data.
   * @param charId The character this vocal track will be for.
   * @param instId The instrumental this vocal track will be for.
   */
  public static function loadInstFromBytes(state:ChartEditorState, bytes:Bytes, instId:String = '', wipeFirst:Bool = false):Bool
  {
    if (instId == '') instId = 'default';
    if (wipeFirst) wipeInstrumentalData(state);
    state.audioInstTrackData.set(instId, bytes);
    return true;
  }

  public static function switchToInstrumental(state:ChartEditorState, instId:String = '', playerId:String, opponentId:String):Bool
  {
    var result:Bool = playInstrumental(state, instId);
    if (!result) return false;

    stopExistingVocals(state);
    result = playVocals(state, BF, playerId, instId);
    // if (!result) return false;
    result = playVocals(state, DAD, opponentId, instId);
    // if (!result) return false;

    return true;
  }

  /**
   * Tell the Chart Editor to select a specific instrumental track, that is already loaded.
   */
  public static function playInstrumental(state:ChartEditorState, instId:String = ''):Bool
  {
    if (instId == '') instId = 'default';
    var instTrackData:Null<Bytes> = state.audioInstTrackData.get(instId);
    var instTrack:Null<FunkinSound> = SoundUtil.buildSoundFromBytes(instTrackData);
    if (instTrack == null) return false;

    stopExistingInstrumental(state);
    state.audioInstTrack = instTrack;
    state.postLoadInstrumental();
    // Workaround for a bug where FlxG.sound.music.update() was being called twice.
    FlxG.sound.list.remove(instTrack);
    return true;
  }

  public static function stopExistingInstrumental(state:ChartEditorState):Void
  {
    if (state.audioInstTrack != null)
    {
      state.audioInstTrack.stop();
      state.audioInstTrack.destroy();
      state.audioInstTrack = null;
    }
  }

  /**
   * Tell the Chart Editor to select a specific vocal track, that is already loaded.
   */
  public static function playVocals(state:ChartEditorState, charType:CharacterType, charId:String, instId:String = ''):Bool
  {
    var trackId:String = '${charId}${instId == '' ? '' : '-${instId}'}';
    var vocalTrackData:Null<Bytes> = state.audioVocalTrackData.get(trackId);
    var vocalTrack:Null<FunkinSound> = SoundUtil.buildSoundFromBytes(vocalTrackData);

    if (state.audioVocalTrackGroup == null) state.audioVocalTrackGroup = new VoicesGroup();
    if (state.audioVisGroup == null) state.audioVisGroup = new PolygonVisGroup();

    if (vocalTrack != null)
    {
      switch (charType)
      {
        case BF:
          state.audioVocalTrackGroup.addPlayerVoice(vocalTrack);
          state.audioVisGroup.addPlayerVis(vocalTrack);
          state.audioVisGroup.playerVis.x = 885;
          state.audioVisGroup.playerVis.realtimeVisLenght = Conductor.instance.getStepTimeInMs(16) * 0.00195;
          state.audioVisGroup.playerVis.daHeight = (ChartEditorState.GRID_SIZE) * 16;
          state.audioVisGroup.playerVis.detail = 1;

          state.audioVocalTrackGroup.playerVoicesOffset = state.currentSongOffsets.getVocalOffset(charId);
          return true;
        case DAD:
          state.audioVocalTrackGroup.addOpponentVoice(vocalTrack);
          state.audioVisGroup.addOpponentVis(vocalTrack);
          state.audioVisGroup.opponentVis.x = 405;

          state.audioVisGroup.opponentVis.realtimeVisLenght = Conductor.instance.getStepTimeInMs(16) * 0.00195;
          state.audioVisGroup.opponentVis.daHeight = (ChartEditorState.GRID_SIZE) * 16;
          state.audioVisGroup.opponentVis.detail = 1;

          state.audioVocalTrackGroup.opponentVoicesOffset = state.currentSongOffsets.getVocalOffset(charId);

          return true;
        case OTHER:
          state.audioVocalTrackGroup.add(vocalTrack);
          // TODO: Add offset for other characters.
          return true;
        default:
          // Do nothing.
      }
    }

    return false;
  }

  public static function stopExistingVocals(state:ChartEditorState):Void
  {
    if (state.audioVocalTrackGroup != null)
    {
      state.audioVocalTrackGroup.clear();
    }
  }

  /**
   * Play a sound effect.
   * Automatically cleans up after itself and recycles previous FlxSound instances if available, for performance.
   * @param path The path to the sound effect. Use `Paths` to build this.
   */
  public static function playSound(_state:ChartEditorState, path:String, volume:Float = 1.0):Void
  {
    var snd:FlxSound = FlxG.sound.list.recycle(FlxSound) ?? new FlxSound();
    var asset:Null<FlxSoundAsset> = FlxG.sound.cache(path);
    if (asset == null)
    {
      trace('WARN: Failed to play sound $path, asset not found.');
      return;
    }
    snd.loadEmbedded(asset);
    snd.autoDestroy = true;
    FlxG.sound.list.add(snd);
    snd.volume = volume;
    snd.play();
  }

  public static function wipeInstrumentalData(state:ChartEditorState):Void
  {
    state.audioInstTrackData.clear();
    stopExistingInstrumental(state);
  }

  public static function wipeVocalData(state:ChartEditorState):Void
  {
    state.audioVocalTrackData.clear();
    stopExistingVocals(state);
  }

  /**
   * Create a list of ZIP file entries from the current loaded instrumental tracks in the chart eidtor.
   * @param state The chart editor state.
   * @return `Array<haxe.zip.Entry>`
   */
  public static function makeZIPEntriesFromInstrumentals(state:ChartEditorState):Array<haxe.zip.Entry>
  {
    var zipEntries = [];

    var instTrackIds = state.audioInstTrackData.keys().array();
    for (key in instTrackIds)
    {
      if (key == 'default')
      {
        var data:Null<Bytes> = state.audioInstTrackData.get('default');
        if (data == null)
        {
          trace('[WARN] Failed to access inst track ($key)');
          continue;
        }
        zipEntries.push(FileUtil.makeZIPEntryFromBytes('Inst.ogg', data));
      }
      else
      {
        var data:Null<Bytes> = state.audioInstTrackData.get(key);
        if (data == null)
        {
          trace('[WARN] Failed to access inst track ($key)');
          continue;
        }
        zipEntries.push(FileUtil.makeZIPEntryFromBytes('Inst-${key}.ogg', data));
      }
    }

    return zipEntries;
  }

  /**
   * Create a list of ZIP file entries from the current loaded vocal tracks in the chart eidtor.
   * @param state The chart editor state.
   * @return `Array<haxe.zip.Entry>`
   */
  public static function makeZIPEntriesFromVocals(state:ChartEditorState):Array<haxe.zip.Entry>
  {
    var zipEntries = [];

    var vocalTrackIds = state.audioVocalTrackData.keys().array();
    for (key in state.audioVocalTrackData.keys())
    {
      var data:Null<Bytes> = state.audioVocalTrackData.get(key);
      if (data == null)
      {
        trace('[WARN] Failed to access vocal track ($key)');
        continue;
      }
      zipEntries.push(FileUtil.makeZIPEntryFromBytes('Voices-${key}.ogg', data));
    }

    return zipEntries;
  }
}
