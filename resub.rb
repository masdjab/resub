# subtitle rebuilder
# written by masdjab
# 201127

require 'json'


class SubtitleCorrector
  def correct_subtitle(subtitle, corrections)
    items = corrections["corrections"].sort{|a,b|a["actual"] <=> b["actual"]}
    
    default_factor = (items[-1]["expected"] - items[0]["expected"]) / (items[-1]["actual"] - items[0]["actual"])
    
    corrs = 
      (1...items.count).map do |i|
        i0 = items[i - 1]
        i1 = items[i]
        a0 = i0["actual"]
        a1 = i1["actual"]
        e0 = i0["expected"]
        e1 = i1["expected"]
        cf = (e1 - e0) / (a1 - a0)
        
        {"start" => a0, "end" => (a1 - 0.001).round(3), "base" => e0, "factor" => cf}
      end
    
    if corrs[0]["start"] > 0.0
      new_item = 
        {
          "start" => 0.0, 
          "end" => (corrs[0]["start"] - 0.001).round(3), 
          "base" => 0.0, 
          "factor" => default_factor
        }
      corrs.insert(0, new_item)
    end
    
    if corrs[-1]["end"] < (mt = (99 * 3600) + (59 * 60) + 59.999)
      new_item = 
        {
          "start" => (corrs[-1]["end"] + 0.001).round(3), 
          "end" => mt, 
          "base" => corrs[-1]["end"], 
          "factor" => default_factor
        }
      corrs << new_item
    end
    
    subtitle.each do |s|
      c = corrs.find{|x|(s["start"] >= x["start"]) && (s["end"] < x["end"])}
      s["start"] = c["base"] + ((s["start"] - c["start"]) * c["factor"])
      s["end"] = c["base"] + ((s["end"] - c["start"]) * c["factor"])
    end
    
    subtitle
  end
end


class SubtitleRebuilder
  private
  def initialize(ori_subtitle_file, new_subtitle_file, correction_file, subtitle_corrector)
    @ori_subtitle_file = ori_subtitle_file
    @new_subtitle_file = new_subtitle_file
    @correction_file = correction_file
    @subtitle_corrector = subtitle_corrector
  end
  def self.time_str_to_secs(time_str)
    times = time_str.lines(":").map{|x|x.gsub(",", ".").to_f}
    (times[0] * 3600) + (times[1] * 60) + times[2]
  end
  def self.secs_to_time_str(secs)
    t = secs
    t = (t - (s = t % 60)).to_i
    m = (t = (t / 60)) % 60
    h = t / 60
    ("%02d:%02d:%06.3f" % [h, m, s]).gsub(".", ",")
  end
  def self.load_subtitle(file)
    content = File.read(file)
    subtitle = 
      content.lines("#{$/}#{$/}").map{|c|
        lines = c.lines.map{|x|x.chomp}
        
        if lines[0].index(":")
          lines.insert(0, nil)
        else
          lines[0] = lines[0].to_i
        end
        
        times = lines[1].lines(" --> ").map{|x|self.time_str_to_secs(x.chomp(" --> "))}
        texts = lines[2..-1].join($/).chomp($/)
        
        attrs = lines[0] ? {"item_id" => lines[0].to_i} : {}
        attrs["start"] = times[0]
        attrs["end"] = times[1]
        attrs["text"] = texts
        
        attrs
      }
    
    subtitle
  end
  def self.load_corrections(file)
    corrections = JSON.parse(File.read(file))
    
    corrections["corrections"].each do |c|
      c["actual"] = self.time_str_to_secs(c["actual"])
      c["expected"] = self.time_str_to_secs(c["expected"])
    end
    
    corrections
  end
  def self.subtitle_to_string(subtitle)
    items = 
      subtitle.map do |s|
        times = [s["start"], s["end"]].map{|x|self.secs_to_time_str(x)}
        attr0 = s["item_id"] ? [s["item_id"]] : []
        attr1 = ["#{times[0]} --> #{times[1]}", s["text"]]
        (attr0 + attr1).join($/)
      end
    
    texts = items.join("#{$/}#{$/}") + $/
  end
  def self.save_subtitle(file, str)
    File.write(file, str)
  end
  
  public
  def correct_subtitle(subtitle, corrections)
    @subtitle_corrector.correct_subtitle subtitle, corrections
  end
  def rebuild
    original_subtitle = self.class.load_subtitle(@ori_subtitle_file)
    corrections = self.class.load_corrections(@correction_file)
    new_subtitle = self.correct_subtitle(original_subtitle, corrections)
    str_subtitle = self.class.subtitle_to_string(new_subtitle)
    self.class.save_subtitle @new_subtitle_file, str_subtitle
  end
end


class SubtitleRebuilderUI
  def self.handle_request(args)
    if args.count != 3
      puts "Usage: ruby resub.rb ori_subtitle_file new_subtitle_file correction_file"
      puts "ex: ruby resub.rb \"The Movie - Original.srt\" \"The Movie.srt\" \"The Movie.json\""
    else
      ori_subtitle_file = args[0]
      new_subtitle_file = args[1]
      correction_file = args[2]
      
      corrector = SubtitleCorrector.new
      rebuilder = SubtitleRebuilder.new(ori_subtitle_file, new_subtitle_file, correction_file, corrector)
      rebuilder.rebuild
    end
  end
end


SubtitleRebuilderUI.handle_request ARGV
