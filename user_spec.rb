require 'airborne'
require 'json'

describe 'users api endpoint' do

  let(:endpt){'http://actenum-qa-test.us-west-2.elasticbeanstalk.com/api/users'}

  def get_users
    get endpt
    json_body
  end

  before(:each) do
    post "#{endpt}/reset"
  end

  after(:each) do |example|
    if example.exception
      puts 'response info: '
      begin
        puts json_body
        puts response.code
      rescue
        puts body
        puts response.code
      rescue
        puts response.code
      rescue
        puts 'no response'
      end
    end
  end

  it 'should get users' do
    users = get_users
    puts users
    user = users[0]
    expect(user).to include(:id, :firstName, :lastName, :email)
  end

  it 'should get specific user' do
    get endpt
    user = json_body[0]
    puts user[:id]

    get "#{endpt}/#{user[:id]}"
    puts json_body
  end

  it 'add user with required fields' do
    post endpt, {firstName: 'mickey', lastName: 'mouse', email: 'mickey.mouse@disney.mail'}
    puts json_body
    get endpt
    expect(json_body).to include(a_hash_including(firstName: 'mickey', lastName: 'mouse'))

    # check the generated fields are present
  end

  it 'add user without required fields' do
    post endpt, {apple: 'orange'}
    # bug: expect some error message
    # 400 is for not found
    puts body
    expect(response.code).to be 400
  end

  it 'update user without required fields' do
    get endpt
    user = json_body[0]
    puts user[:id]

    put endpt, {id: user[:id]}
  end


  it 'update nonexisting user' do
    get endpt
    user = json_body[0]

    put endpt, {id: user[:id]}
    expect(response.code).to be 400
    # puts body
  end

  it 'add user with same email as another user' do

  end

  it 'generate duplicate 1' do

  end

end
