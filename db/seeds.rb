# coding: utf-8

User.create!(name: "管理者",
             email: "sample@email.com",
             password: "password",
             password_confirmation: "password",
             affiliation: "ビッグ・ダディ",
             admin: true)

User.create!(name: "上長Ａ",
             email: "sample-superior-A@email.com",
             password: "password",
             password_confirmation: "password",
             affiliation: "次長",
             superior: true)

User.create!(name: "上長Ｂ",
             email: "sample-superior-B@email.com",
             password: "password",
             password_confirmation: "password",
             affiliation: "課長",
             superior: true)

5.times do |n|
  name  = Faker::Name.name
  email = "sample-#{n+1}@email.com"
  password = "password"
  User.create!(name: name,
               email: email,
               password: password,
               password_confirmation: password)
end
