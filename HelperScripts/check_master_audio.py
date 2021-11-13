# Search scenes and find which audiostream scenes don't have a bus selected
import os
path = '..\\'

def is_scene(file: str):
    return file.endswith(".tscn")


def has_audio_without_bus(file):
    """
    We are checking if there is something like this 
    [node name="Jump3" type="AudioStreamPlayer" parent="Sounds"]
    bus = "SoundEffects"
    """
    try:
        with open(file) as fp:
            audio_scene_started = False
            bus_appeared = False
            for line in fp.readlines():
                if line.startswith('[') and audio_scene_started:
                    if bus_appeared:
                        audio_scene_started = False
                        bus_appeared = False
                    else:
                        return True
                if line.startswith('[node') and 'AudioStream' in line:
                    audio_scene_started = True
                    bus_appeared = False
                if audio_scene_started and line.startswith('bus'):
                    bus_appeared = True

        return audio_scene_started and not bus_appeared
    except Exception as e:
        print(f"exception ocurred in {file}")
        print(e)
        return False


def get_non_bus_scenes(file):
    if os.path.isdir(file):
        return get_dir_non_bus_scenes(file)
    else:
        if is_scene(file) and has_audio_without_bus(file):
            return [file]
        else:
            return []


def get_dir_non_bus_scenes(dir_name):
    all_non_bus_scenes = []
    for filename in os.listdir(dir_name):
        all_non_bus_scenes += get_non_bus_scenes(dir_name + '\\' + filename)
    return all_non_bus_scenes


all_non_bus_scenes = get_dir_non_bus_scenes(path)
for scene in all_non_bus_scenes:
    print(scene)


