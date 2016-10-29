# 按行读取文件，存为数组
items = IO.readlines("origin_answers.txt")

# 将所有空格和换行符删除，并按照':'分割为数组
results = items.map{ |i| i.gsub(/\s/, '').split(':') }

# 删除含有数字10的项目
results.reject!{ |res| res[0].length > 4 }


# 将所有无解的条目，替换成一个0表示答案
results.each do |res|
    if res[1].include?("noanswer!") 
        res[1] = "00000000000$"
    else
        res[1] = res[1].slice(1...-4) + '$'
    end    
end

results.each do |r|
    p r.join if r.join.length != 16
end
# 通过换行符分割每一条数据，然后写入目标文件
File.open("answers.txt","w") do |f|
    results.each do |res|
        f.syswrite(res.join)
    end
end