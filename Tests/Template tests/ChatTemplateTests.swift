//
//  ChatTemplateTests.swift
//
//
//  Created by John Mai on 2024/3/24.
//

import XCTest

@testable import Jinja

final class ChatTemplateTests: XCTestCase {
    let messages: [[String: String]] = [
        [
            "role": "user",
            "content": "Hello, how are you?",
        ],
        [
            "role": "assistant",
            "content": "I'm doing great. How can I help you today?",
        ],
        [
            "role": "user",
            "content": "I'd like to show off how chat templating works!",
        ],
    ]

    lazy var messagesWithSystemPrompt: [[String: String]] =
        [
            [
                "role": "system",
                "content": "You are a friendly chatbot who always responds in the style of a pirate",
            ]
        ] + messages

    func testGenericChatTemplate() throws {
        let chatTemplate =
            "{% for message in messages %}{{'<|im_start|>' + message['role'] + '\n' + message['content'] + '<|im_end|>' + '\n'}}{% endfor %}{% if add_generation_prompt %}{{ '<|im_start|>assistant\n' }}{% endif %}"
        let template = try Template(chatTemplate)
        let result = try template.render([
            "messages": messages,
            "add_generation_prompt": false,
        ])
        let target =
            "<|im_start|>user\nHello, how are you?<|im_end|>\n<|im_start|>assistant\nI'm doing great. How can I help you today?<|im_end|>\n<|im_start|>user\nI'd like to show off how chat templating works!<|im_end|>\n"

        if target != result {
            print("::: testGenericChatTemplate failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testFacebookBlenderbot400MDistill() throws {
        let chatTemplate =
            "{% for message in messages %}{% if message['role'] == 'user' %}{{ ' ' }}{% endif %}{{ message['content'] }}{% if not loop.last %}{{ '  ' }}{% endif %}{% endfor %}{{ eos_token }}"
        let template = try Template(chatTemplate)
        let result = try template.render([
            "messages": messages,
            "eos_token": "</s>",
        ])
        let target =
            " Hello, how are you?  I'm doing great. How can I help you today?   I'd like to show off how chat templating works!</s>"

        if target != result {
            print("::: testFacebookBlenderbot400MDistill failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testFacebookBlenderbotSmall90M() throws {
        let chatTemplate =
            "{% for message in messages %}{% if message['role'] == 'user' %}{{ ' ' }}{% endif %}{{ message['content'] }}{% if not loop.last %}{{ '  ' }}{% endif %}{% endfor %}{{ eos_token }}"
        let template = try Template(chatTemplate)
        let result = try template.render([
            "messages": messages,
            "eos_token": "</s>",
        ])
        let target =
            " Hello, how are you?  I'm doing great. How can I help you today?   I'd like to show off how chat templating works!</s>"

        if target != result {
            print("::: testFacebookBlenderbotSmall90M failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testBigscienceBloom() throws {
        let chatTemplate = "{% for message in messages %}{{ message.content }}{{ eos_token }}{% endfor %}"
        let template = try Template(chatTemplate)
        let result = try template.render([
            "messages": messages,
            "eos_token": "</s>",
        ])
        let target =
            "Hello, how are you?</s>I'm doing great. How can I help you today?</s>I'd like to show off how chat templating works!</s>"

        if target != result {
            print("::: testBigscienceBloom failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testEleutherAIGptNeox20b() throws {
        let chatTemplate = "{% for message in messages %}{{ message.content }}{{ eos_token }}{% endfor %}"
        let template = try Template(chatTemplate)
        let result = try template.render([
            "messages": messages,
            "eos_token": "<|endoftext|>",
        ])
        let target =
            "Hello, how are you?<|endoftext|>I'm doing great. How can I help you today?<|endoftext|>I'd like to show off how chat templating works!<|endoftext|>"

        if target != result {
            print("::: testEleutherAIGptNeox20b failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testGPT2() throws {
        let chatTemplate = "{% for message in messages %}{{ message.content }}{{ eos_token }}{% endfor %}"
        let template = try Template(chatTemplate)
        let result = try template.render([
            "messages": messages,
            "eos_token": "<|endoftext|>",
        ])
        let target =
            "Hello, how are you?<|endoftext|>I'm doing great. How can I help you today?<|endoftext|>I'd like to show off how chat templating works!<|endoftext|>"

        if target != result {
            print("::: testGPT2 failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testHfInternalTestingLlamaTokenizer1() throws {
        let chatTemplate =
            "{% if messages[0]['role'] == 'system' %}{% set loop_messages = messages[1:] %}{% set system_message = messages[0]['content'] %}{% elif USE_DEFAULT_PROMPT == true and not '<<SYS>>' in messages[0]['content'] %}{% set loop_messages = messages %}{% set system_message = 'DEFAULT_SYSTEM_MESSAGE' %}{% else %}{% set loop_messages = messages %}{% set system_message = false %}{% endif %}{% for message in loop_messages %}{% if (message['role'] == 'user') != (loop.index0 % 2 == 0) %}{{ raise_exception('Conversation roles must alternate user/assistant/user/assistant/...') }}{% endif %}{% if loop.index0 == 0 and system_message != false %}{% set content = '<<SYS>>\\n' + system_message + '\\n<</SYS>>\\n\\n' + message['content'] %}{% else %}{% set content = message['content'] %}{% endif %}{% if message['role'] == 'user' %}{{ bos_token + '[INST] ' + content.strip() + ' [/INST]' }}{% elif message['role'] == 'system' %}{{ '<<SYS>>\\n' + content.strip() + '\\n<</SYS>>\\n\\n' }}{% elif message['role'] == 'assistant' %}{{ ' ' + content.strip() + ' ' + eos_token }}{% endif %}{% endfor %}"
        let template = try Template(chatTemplate)
        let result = try template.render([
            "messages": messagesWithSystemPrompt,
            "bos_token": "<s>",
            "eos_token": "</s>",
            "USE_DEFAULT_PROMPT": true,
        ])
        let target =
            "<s>[INST] <<SYS>>\nYou are a friendly chatbot who always responds in the style of a pirate\n<</SYS>>\n\nHello, how are you? [/INST] I'm doing great. How can I help you today? </s><s>[INST] I'd like to show off how chat templating works! [/INST]"

        if target != result {
            print("::: testHfInternalTestingLlamaTokenizer1 failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testHfInternalTestingLlamaTokenizer2() throws {
        let chatTemplate =
            "{% if messages[0]['role'] == 'system' %}{% set loop_messages = messages[1:] %}{% set system_message = messages[0]['content'] %}{% elif USE_DEFAULT_PROMPT == true and not '<<SYS>>' in messages[0]['content'] %}{% set loop_messages = messages %}{% set system_message = 'DEFAULT_SYSTEM_MESSAGE' %}{% else %}{% set loop_messages = messages %}{% set system_message = false %}{% endif %}{% for message in loop_messages %}{% if (message['role'] == 'user') != (loop.index0 % 2 == 0) %}{{ raise_exception('Conversation roles must alternate user/assistant/user/assistant/...') }}{% endif %}{% if loop.index0 == 0 and system_message != false %}{% set content = '<<SYS>>\\n' + system_message + '\\n<</SYS>>\\n\\n' + message['content'] %}{% else %}{% set content = message['content'] %}{% endif %}{% if message['role'] == 'user' %}{{ bos_token + '[INST] ' + content.strip() + ' [/INST]' }}{% elif message['role'] == 'system' %}{{ '<<SYS>>\\n' + content.strip() + '\\n<</SYS>>\\n\\n' }}{% elif message['role'] == 'assistant' %}{{ ' ' + content.strip() + ' ' + eos_token }}{% endif %}{% endfor %}"
        let template = try Template(chatTemplate)
        let result = try template.render([
            "messages": messages,
            "bos_token": "<s>",
            "eos_token": "</s>",
            "USE_DEFAULT_PROMPT": true,
        ])
        let target =
            "<s>[INST] <<SYS>>\nDEFAULT_SYSTEM_MESSAGE\n<</SYS>>\n\nHello, how are you? [/INST] I'm doing great. How can I help you today? </s><s>[INST] I'd like to show off how chat templating works! [/INST]"

        if target != result {
            print("::: testHfInternalTestingLlamaTokenizer2 failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testHfInternalTestingLlamaTokenizer3() throws {
        let chatTemplate =
            "{% if messages[0]['role'] == 'system' %}{% set loop_messages = messages[1:] %}{% set system_message = messages[0]['content'] %}{% elif USE_DEFAULT_PROMPT == true and not '<<SYS>>' in messages[0]['content'] %}{% set loop_messages = messages %}{% set system_message = 'DEFAULT_SYSTEM_MESSAGE' %}{% else %}{% set loop_messages = messages %}{% set system_message = false %}{% endif %}{% for message in loop_messages %}{% if (message['role'] == 'user') != (loop.index0 % 2 == 0) %}{{ raise_exception('Conversation roles must alternate user/assistant/user/assistant/...') }}{% endif %}{% if loop.index0 == 0 and system_message != false %}{% set content = '<<SYS>>\\n' + system_message + '\\n<</SYS>>\\n\\n' + message['content'] %}{% else %}{% set content = message['content'] %}{% endif %}{% if message['role'] == 'user' %}{{ bos_token + '[INST] ' + content.strip() + ' [/INST]' }}{% elif message['role'] == 'system' %}{{ '<<SYS>>\\n' + content.strip() + '\\n<</SYS>>\\n\\n' }}{% elif message['role'] == 'assistant' %}{{ ' ' + content.strip() + ' ' + eos_token }}{% endif %}{% endfor %}"
        let template = try Template(chatTemplate)
        let result = try template.render([
            "messages": [
                [
                    "role": "user",
                    "content": "<<SYS>>\nYou are a helpful assistant\n<</SYS>> Hello, how are you?",
                ],
                [
                    "role": "assistant",
                    "content": "I'm doing great. How can I help you today?",
                ],
                [
                    "role": "user",
                    "content": "I'd like to show off how chat templating works!",
                ],
            ],
            "bos_token": "<s>",
            "eos_token": "</s>",
            "USE_DEFAULT_PROMPT": true,
        ])
        let target =
            "<s>[INST] <<SYS>>\nYou are a helpful assistant\n<</SYS>> Hello, how are you? [/INST] I'm doing great. How can I help you today? </s><s>[INST] I'd like to show off how chat templating works! [/INST]"

        if target != result {
            print("::: testHfInternalTestingLlamaTokenizer3 failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testOpenaiWhisperLargeV3() throws {
        let chatTemplate = "{% for message in messages %}{{ message.content }}{{ eos_token }}{% endfor %}"
        let template = try Template(chatTemplate)
        let result = try template.render([
            "messages": messages,
            "eos_token": "<|endoftext|>",
        ])
        let target =
            "Hello, how are you?<|endoftext|>I'm doing great. How can I help you today?<|endoftext|>I'd like to show off how chat templating works!<|endoftext|>"

        if target != result {
            print("::: testOpenaiWhisperLargeV3 failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testQwenQwen1_5_1_8BChat1() throws {
        let chatTemplate =
            "{% for message in messages %}{% if loop.first and messages[0]['role'] != 'system' %}{{ '<|im_start|>system\nYou are a helpful assistant<|im_end|>\n' }}{% endif %}{{'<|im_start|>' + message['role'] + '\n' + message['content']}}{% if (loop.last and add_generation_prompt) or not loop.last %}{{ '<|im_end|>' + '\n'}}{% endif %}{% endfor %}{% if add_generation_prompt and messages[-1]['role'] != 'assistant' %}{{ '<|im_start|>assistant\n' }}{% endif %}"
        let template = try Template(chatTemplate)
        let result = try template.render([
            "messages": messages,
            "add_generation_prompt": true,
        ])
        let target =
            "<|im_start|>system\nYou are a helpful assistant<|im_end|>\n<|im_start|>user\nHello, how are you?<|im_end|>\n<|im_start|>assistant\nI\'m doing great. How can I help you today?<|im_end|>\n<|im_start|>user\nI\'d like to show off how chat templating works!<|im_end|>\n<|im_start|>assistant\n"

        if target != result {
            print("::: testQwenQwen1_5_1_8BChat1 failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testQwenQwen1_5_1_8BChat2() throws {
        let chatTemplate =
            "{% for message in messages %}{% if loop.first and messages[0]['role'] != 'system' %}{{ '<|im_start|>system\nYou are a helpful assistant<|im_end|>\n' }}{% endif %}{{'<|im_start|>' + message['role'] + '\n' + message['content']}}{% if (loop.last and add_generation_prompt) or not loop.last %}{{ '<|im_end|>' + '\n'}}{% endif %}{% endfor %}{% if add_generation_prompt and messages[-1]['role'] != 'assistant' %}{{ '<|im_start|>assistant\n' }}{% endif %}"
        let template = try Template(chatTemplate)
        let result = try template.render([
            "messages": messagesWithSystemPrompt,
            "add_generation_prompt": true,
        ])
        let target =
            "<|im_start|>system\nYou are a friendly chatbot who always responds in the style of a pirate<|im_end|>\n<|im_start|>user\nHello, how are you?<|im_end|>\n<|im_start|>assistant\nI\'m doing great. How can I help you today?<|im_end|>\n<|im_start|>user\nI\'d like to show off how chat templating works!<|im_end|>\n<|im_start|>assistant\n"

        if target != result {
            print("::: testQwenQwen1_5_1_8BChat2 failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testQwenQwen1_5_1_8BChat3() throws {
        let chatTemplate =
            "{% for message in messages %}{% if loop.first and messages[0]['role'] != 'system' %}{{ '<|im_start|>system\nYou are a helpful assistant<|im_end|>\n' }}{% endif %}{{'<|im_start|>' + message['role'] + '\n' + message['content']}}{% if (loop.last and add_generation_prompt) or not loop.last %}{{ '<|im_end|>' + '\n'}}{% endif %}{% endfor %}{% if add_generation_prompt and messages[-1]['role'] != 'assistant' %}{{ '<|im_start|>assistant\n' }}{% endif %}"
        let template = try Template(chatTemplate)
        let result = try template.render([
            "messages": messagesWithSystemPrompt
        ])
        let target =
            "<|im_start|>system\nYou are a friendly chatbot who always responds in the style of a pirate<|im_end|>\n<|im_start|>user\nHello, how are you?<|im_end|>\n<|im_start|>assistant\nI\'m doing great. How can I help you today?<|im_end|>\n<|im_start|>user\nI\'d like to show off how chat templating works!"

        if target != result {
            print("::: testQwenQwen1_5_1_8BChat3 failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testTHUDMChatglm36b() throws {
        let chatTemplate =
            "{% for message in messages %}{% if loop.first %}[gMASK]sop<|{{ message['role'] }}|>\n {{ message['content'] }}{% else %}<|{{ message['role'] }}|>\n {{ message['content'] }}{% endif %}{% endfor %}{% if add_generation_prompt %}<|assistant|>{% endif %}"
        let template = try Template(chatTemplate)
        let result = try template.render([
            "messages": messagesWithSystemPrompt
        ])
        let target =
            "[gMASK]sop<|system|>\n You are a friendly chatbot who always responds in the style of a pirate<|user|>\n Hello, how are you?<|assistant|>\n I\'m doing great. How can I help you today?<|user|>\n I\'d like to show off how chat templating works!"

        if target != result {
            print("::: testTHUDMChatglm36b failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testGoogleGemma2bIt() throws {
        let chatTemplate =
            "{{ bos_token }}{% if messages[0]['role'] == 'system' %}{{ raise_exception('System role not supported') }}{% endif %}{% for message in messages %}{% if (message['role'] == 'user') != (loop.index0 % 2 == 0) %}{{ raise_exception('Conversation roles must alternate user/assistant/user/assistant/...') }}{% endif %}{% if (message['role'] == 'assistant') %}{% set role = 'model' %}{% else %}{% set role = message['role'] %}{% endif %}{{ '<start_of_turn>' + role + '\n' + message['content'] | trim + '<end_of_turn>\n' }}{% endfor %}{% if add_generation_prompt %}{{'<start_of_turn>model\n'}}{% endif %}"
        let template = try Template(chatTemplate)
        let result = try template.render([
            "messages": messages
        ])
        let target =
            "<start_of_turn>user\nHello, how are you?<end_of_turn>\n<start_of_turn>model\nI\'m doing great. How can I help you today?<end_of_turn>\n<start_of_turn>user\nI\'d like to show off how chat templating works!<end_of_turn>\n"

        if target != result {
            print("::: testGoogleGemma2bIt failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testQwenQwen2_5_0_5BInstruct() throws {
        let chatTemplate =
            "{%- if tools %}\n    {{- '<|im_start|>system\\n' }}\n    {%- if messages[0]['role'] == 'system' %}\n        {{- messages[0]['content'] }}\n    {%- else %}\n        {{- 'You are Qwen, created by Alibaba Cloud. You are a helpful assistant.' }}\n    {%- endif %}\n    {{- \"\\n\\n# Tools\\n\\nYou may call one or more functions to assist with the user query.\\n\\nYou are provided with function signatures within <tools></tools> XML tags:\\n<tools>\" }}\n    {%- for tool in tools %}\n        {{- \"\\n\" }}\n        {{- tool | tojson }}\n    {%- endfor %}\n    {{- \"\\n</tools>\\n\\nFor each function call, return a json object with function name and arguments within <tool_call></tool_call> XML tags:\\n<tool_call>\\n{\\\"name\\\": <function-name>, \\\"arguments\\\": <args-json-object>}\\n</tool_call><|im_end|>\\n\" }}\n{%- else %}\n    {%- if messages[0]['role'] == 'system' %}\n        {{- '<|im_start|>system\\n' + messages[0]['content'] + '<|im_end|>\\n' }}\n    {%- else %}\n        {{- '<|im_start|>system\\nYou are Qwen, created by Alibaba Cloud. You are a helpful assistant.<|im_end|>\\n' }}\n    {%- endif %}\n{%- endif %}\n{%- for message in messages %}\n    {%- if (message.role == \"user\") or (message.role == \"system\" and not loop.first) or (message.role == \"assistant\" and not message.tool_calls) %}\n        {{- '<|im_start|>' + message.role + '\\n' + message.content + '<|im_end|>' + '\\n' }}\n    {%- elif message.role == \"assistant\" %}\n        {{- '<|im_start|>' + message.role }}\n        {%- if message.content %}\n            {{- '\\n' + message.content }}\n        {%- endif %}\n        {%- for tool_call in message.tool_calls %}\n            {%- if tool_call.function is defined %}\n                {%- set tool_call = tool_call.function %}\n            {%- endif %}\n            {{- '\\n<tool_call>\\n{\"name\": \"' }}\n            {{- tool_call.name }}\n            {{- '\", \"arguments\": ' }}\n            {{- tool_call.arguments | tojson }}\n            {{- '}\\n</tool_call>' }}\n        {%- endfor %}\n        {{- '<|im_end|>\\n' }}\n    {%- elif message.role == \"tool\" %}\n        {%- if (loop.index0 == 0) or (messages[loop.index0 - 1].role != \"tool\") %}\n            {{- '<|im_start|>user' }}\n        {%- endif %}\n        {{- '\\n<tool_response>\\n' }}\n        {{- message.content }}\n        {{- '\\n</tool_response>' }}\n        {%- if loop.last or (messages[loop.index0 + 1].role != \"tool\") %}\n            {{- '<|im_end|>\\n' }}\n        {%- endif %}\n    {%- endif %}\n{%- endfor %}\n{%- if add_generation_prompt %}\n    {{- '<|im_start|>assistant\\n' }}\n{%- endif %}\n"
        let template = try Template(chatTemplate)
        let result = try template.render([
            "messages": messages
        ])
        let target =
            "<|im_start|>system\nYou are Qwen, created by Alibaba Cloud. You are a helpful assistant.<|im_end|>\n<|im_start|>user\nHello, how are you?<|im_end|>\n<|im_start|>assistant\nI\'m doing great. How can I help you today?<|im_end|>\n<|im_start|>user\nI\'d like to show off how chat templating works!<|im_end|>\n"

        if target != result {
            print("::: testQwenQwen2_5_0_5BInstruct failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testHuggingFaceH4Zephyr7bBetaAddGenerationPromptFalse() throws {
        let chatTemplate =
            "{% for message in messages %}\n{% if message['role'] == 'user' %}\n{{ '<|user|>\n' + message['content'] + eos_token }}\n{% elif message['role'] == 'system' %}\n{{ '<|system|>\n' + message['content'] + eos_token }}\n{% elif message['role'] == 'assistant' %}\n{{ '<|assistant|>\n'  + message['content'] + eos_token }}\n{% endif %}\n{% if loop.last and add_generation_prompt %}\n{{ '<|assistant|>' }}\n{% endif %}\n{% endfor %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messagesWithSystemPrompt, "eos_token": "</s>",
                "add_generation_prompt": false,
            ] as [String: Any]
        )
        let target =
            "<|system|>\nYou are a friendly chatbot who always responds in the style of a pirate</s>\n<|user|>\nHello, how are you?</s>\n<|assistant|>\nI'm doing great. How can I help you today?</s>\n<|user|>\nI'd like to show off how chat templating works!</s>\n"

        if target != result {
            print("::: testHuggingFaceH4Zephyr7bBetaAddGenerationPromptFalse failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testHuggingFaceH4Zephyr7bBetaAddGenerationPromptTrue() throws {
        let chatTemplate =
            "{% for message in messages %}\n{% if message['role'] == 'user' %}\n{{ '<|user|>\n' + message['content'] + eos_token }}\n{% elif message['role'] == 'system' %}\n{{ '<|system|>\n' + message['content'] + eos_token }}\n{% elif message['role'] == 'assistant' %}\n{{ '<|assistant|>\n'  + message['content'] + eos_token }}\n{% endif %}\n{% if loop.last and add_generation_prompt %}\n{{ '<|assistant|>' }}\n{% endif %}\n{% endfor %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": [
                    [
                        "role": "system",
                        "content": "You are a friendly chatbot who always responds in the style of a pirate",
                    ],
                    ["role": "user", "content": "How many helicopters can a human eat in one sitting?"],
                ], "eos_token": "</s>", "add_generation_prompt": true,
            ] as [String: Any]
        )
        let target =
            "<|system|>\nYou are a friendly chatbot who always responds in the style of a pirate</s>\n<|user|>\nHow many helicopters can a human eat in one sitting?</s>\n<|assistant|>\n"

        if target != result {
            print("::: testHuggingFaceH4Zephyr7bBetaAddGenerationPromptTrue failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testHuggingFaceH4Zephyr7bGemmaV0_1() throws {
        let chatTemplate =
            "{% if messages[0]['role'] == 'user' or messages[0]['role'] == 'system' %}{{ bos_token }}{% endif %}{% for message in messages %}{{ '<|im_start|>' + message['role'] + '\n' + message['content'] + '<|im_end|>' + '\n' }}{% endfor %}{% if add_generation_prompt %}{{ '<|im_start|>assistant\n' }}{% elif messages[-1]['role'] == 'assistant' %}{{ eos_token }}{% endif %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messages, "bos_token": "<bos>", "eos_token": "<eos>",
                "add_generation_prompt": false,
            ] as [String: Any]
        )
        let target =
            "<bos><|im_start|>user\nHello, how are you?<|im_end|>\n<|im_start|>assistant\nI'm doing great. How can I help you today?<|im_end|>\n<|im_start|>user\nI'd like to show off how chat templating works!<|im_end|>\n"

        if target != result {
            print("::: testHuggingFaceH4Zephyr7bGemmaV0_1 failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testTheBlokeMistral7BInstructV0_1GPTQ() throws {
        let chatTemplate =
            "{{ bos_token }}{% for message in messages %}{% if (message['role'] == 'user') != (loop.index0 % 2 == 0) %}{{ raise_exception('Conversation roles must alternate user/assistant/user/assistant/...') }}{% endif %}{% if message['role'] == 'user' %}{{ '[INST] ' + message['content'] + ' [/INST]' }}{% elif message['role'] == 'assistant' %}{{ message['content'] + eos_token + ' ' }}{% else %}{{ raise_exception('Only user and assistant roles are supported!') }}{% endif %}{% endfor %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messages, "bos_token": "<s>", "eos_token": "</s>",
            ] as [String: Any]
        )
        let target =
            "<s>[INST] Hello, how are you? [/INST]I'm doing great. How can I help you today?</s> [INST] I'd like to show off how chat templating works! [/INST]"

        if target != result {
            print("::: testTheBlokeMistral7BInstructV0_1GPTQ failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testMistralaiMixtral8x7BInstructV0_1() throws {
        let chatTemplate =
            "{{ bos_token }}{% for message in messages %}{% if (message['role'] == 'user') != (loop.index0 % 2 == 0) %}{{ raise_exception('Conversation roles must alternate user/assistant/user/assistant/...') }}{% endif %}{% if message['role'] == 'user' %}{{ '[INST] ' + message['content'] + ' [/INST]' }}{% elif message['role'] == 'assistant' %}{{ message['content'] + eos_token}}{% else %}{{ raise_exception('Only user and assistant roles are supported!') }}{% endif %}{% endfor %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messages, "bos_token": "<s>", "eos_token": "</s>",
            ] as [String: Any]
        )
        let target =
            "<s>[INST] Hello, how are you? [/INST]I'm doing great. How can I help you today?</s>[INST] I'd like to show off how chat templating works! [/INST]"

        if target != result {
            print("::: testMistralaiMixtral8x7BInstructV0_1 failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testCognitivecomputationsDolphin2_5Mixtral8x7b() throws {
        let chatTemplate =
            "{% if not add_generation_prompt is defined %}{% set add_generation_prompt = false %}{% endif %}{% for message in messages %}{{'<|im_start|>' + message['role'] + '\n' + message['content'] + '<|im_end|>' + '\n'}}{% endfor %}{% if add_generation_prompt %}{{ '<|im_start|>assistant\n' }}{% endif %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messages
            ] as [String: Any]
        )
        let target =
            "<|im_start|>user\nHello, how are you?<|im_end|>\n<|im_start|>assistant\nI'm doing great. How can I help you today?<|im_end|>\n<|im_start|>user\nI'd like to show off how chat templating works!<|im_end|>\n"

        if target != result {
            print("::: testCognitivecomputationsDolphin2_5Mixtral8x7b failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testOpenchatOpenchat3_5_0106() throws {
        let chatTemplate =
            "{{ bos_token }}{% for message in messages %}{{ 'GPT4 Correct ' + message['role'].title() + ': ' + message['content'] + '<|end_of_turn|>'}}{% endfor %}{% if add_generation_prompt %}{{ 'GPT4 Correct Assistant:' }}{% endif %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messages, "bos_token": "<s>", "eos_token": "</s>",
                "add_generation_prompt": false,
            ] as [String: Any]
        )
        let target =
            "<s>GPT4 Correct User: Hello, how are you?<|end_of_turn|>GPT4 Correct Assistant: I'm doing great. How can I help you today?<|end_of_turn|>GPT4 Correct User: I'd like to show off how chat templating works!<|end_of_turn|>"

        if target != result {
            print("::: testOpenchatOpenchat3_5_0106 failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testUpstageSOLAR10_7BInstructV1_0() throws {
        let chatTemplate =
            "{% for message in messages %}{% if message['role'] == 'system' %}{% if message['content']%}{{'### System:\n' + message['content']+'\n\n'}}{% endif %}{% elif message['role'] == 'user' %}{{'### User:\n' + message['content']+'\n\n'}}{% elif message['role'] == 'assistant' %}{{'### Assistant:\n'  + message['content']}}{% endif %}{% if loop.last and add_generation_prompt %}{{ '### Assistant:\n' }}{% endif %}{% endfor %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messages
            ] as [String: Any]
        )
        let target =
            "### User:\nHello, how are you?\n\n### Assistant:\nI'm doing great. How can I help you today?### User:\nI'd like to show off how chat templating works!\n\n"

        if target != result {
            print("::: testUpstageSOLAR10_7BInstructV1_0 failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testCodellamaCodeLlama70bInstructHf() throws {
        let chatTemplate =
            "{% if messages[0]['role'] == 'system' %}{% set user_index = 1 %}{% else %}{% set user_index = 0 %}{% endif %}{% for message in messages %}{% if (message['role'] == 'user') != ((loop.index0 + user_index) % 2 == 0) %}{{ raise_exception('Conversation roles must alternate user/assistant/user/assistant/...') }}{% endif %}{% if loop.index0 == 0 %}{{ '<s>' }}{% endif %}{% set content = 'Source: ' + message['role'] + '\n\n ' + message['content'] | trim %}{{ content + ' <step> ' }}{% endfor %}{{'Source: assistant\nDestination: user\n\n '}}";
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messages
            ] as [String: Any]
        )
        let target =
            "<s>Source: user\n\n Hello, how are you? <step> Source: assistant\n\n I'm doing great. How can I help you today? <step> Source: user\n\n I'd like to show off how chat templating works! <step> Source: assistant\nDestination: user\n\n "

        if target != result {
            print("::: testCodellamaCodeLlama70bInstructHf failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testDeciDeciLM7BInstruct() throws {
        let chatTemplate =
            "{% for message in messages %}\n{% if message['role'] == 'user' %}\n{{ '### User:\n' + message['content'] }}\n{% elif message['role'] == 'system' %}\n{{ '### System:\n' + message['content'] }}\n{% elif message['role'] == 'assistant' %}\n{{ '### Assistant:\n'  + message['content'] }}\n{% endif %}\n{% if loop.last and add_generation_prompt %}\n{{ '### Assistant:' }}\n{% endif %}\n{% endfor %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messages
            ] as [String: Any]
        )
        let target =
            "### User:\nHello, how are you?\n### Assistant:\nI'm doing great. How can I help you today?\n### User:\nI'd like to show off how chat templating works!\n"

        if target != result {
            print("::: testDeciDeciLM7BInstruct failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testQwenQwen1_5_72BChat() throws {
        let chatTemplate =
            "{% for message in messages %}{% if loop.first and messages[0]['role'] != 'system' %}{{ '<|im_start|>system\nYou are a helpful assistant.<|im_end|>\n' }}{% endif %}{{'<|im_start|>' + message['role'] + '\n' + message['content'] + '<|im_end|>' + '\n'}}{% endfor %}{% if add_generation_prompt %}{{ '<|im_start|>assistant\n' }}{% endif %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messages
            ] as [String: Any]
        )
        let target =
            "<|im_start|>system\nYou are a helpful assistant.<|im_end|>\n<|im_start|>user\nHello, how are you?<|im_end|>\n<|im_start|>assistant\nI'm doing great. How can I help you today?<|im_end|>\n<|im_start|>user\nI'd like to show off how chat templating works!<|im_end|>\n"

        if target != result {
            print("::: testQwenQwen1_5_72BChat failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testDeepseekAiDeepseekLlm7bChat() throws {
        let chatTemplate =
            "{% if not add_generation_prompt is defined %}{% set add_generation_prompt = false %}{% endif %}{{ bos_token }}{% for message in messages %}{% if message['role'] == 'user' %}{{ 'User: ' + message['content'] + '\n\n' }}{% elif message['role'] == 'assistant' %}{{ 'Assistant: ' + message['content'] + eos_token }}{% elif message['role'] == 'system' %}{{ message['content'] + '\n\n' }}{% endif %}{% endfor %}{% if add_generation_prompt %}{{ 'Assistant:' }}{% endif %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messages, "bos_token": "<｜begin of sentence｜>",
                "eos_token": "<｜end of sentence｜>",
            ] as [String: Any]
        )
        let target =
            "<｜begin of sentence｜>User: Hello, how are you?\n\nAssistant: I'm doing great. How can I help you today?<｜end of sentence｜>User: I'd like to show off how chat templating works!\n\n"

        if target != result {
            print("::: testDeepseekAiDeepseekLlm7bChat failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testH2oaiH2oDanube1_8bChat() throws {
        let chatTemplate =
            "{% for message in messages %}{% if message['role'] == 'user' %}{{ '<|prompt|>' + message['content'] + eos_token }}{% elif message['role'] == 'system' %}{{ '<|system|>' + message['content'] + eos_token }}{% elif message['role'] == 'assistant' %}{{ '<|answer|>'  + message['content'] + eos_token }}{% endif %}{% if loop.last and add_generation_prompt %}{{ '<|answer|>' }}{% endif %}{% endfor %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messages, "eos_token": "</s>",
            ] as [String: Any]
        )
        let target =
            "<|prompt|>Hello, how are you?</s><|answer|>I'm doing great. How can I help you today?</s><|prompt|>I'd like to show off how chat templating works!</s>"

        if target != result {
            print("::: testH2oaiH2oDanube1_8bChat failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testInternlmInternlm2Chat7b() throws {
        let chatTemplate =
            "{% if messages[0]['role'] == 'user' or messages[0]['role'] == 'system' %}{{ bos_token }}{% endif %}{% for message in messages %}{{ '<|im_start|>' + message['role'] + '\n' + message['content'] + '<|im_end|>' + '\n' }}{% endfor %}{% if add_generation_prompt %}{{ '<|im_start|>assistant\n' }}{% elif messages[-1]['role'] == 'assistant' %}{{ eos_token }}{% endif %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messages, "bos_token": "<s>", "eos_token": "</s>",
            ] as [String: Any]
        )
        let target =
            "<s><|im_start|>user\nHello, how are you?<|im_end|>\n<|im_start|>assistant\nI'm doing great. How can I help you today?<|im_end|>\n<|im_start|>user\nI'd like to show off how chat templating works!<|im_end|>\n"

        if target != result {
            print("::: testInternlmInternlm2Chat7b failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testTheBlokedeepseekCoder33BInstructAWQ() throws {
        let chatTemplate =
            "{%- set found_item = false -%}\n{%- for message in messages -%}\n    {%- if message['role'] == 'system' -%}\n        {%- set found_item = true -%}\n    {%- endif -%}\n{%- endfor -%}\n{%- if not found_item -%}\n{{'You are an AI programming assistant, utilizing the Deepseek Coder model, developed by Deepseek Company, and you only answer questions related to computer science. For politically sensitive questions, security and privacy issues, and other non-computer science questions, you will refuse to answer.\\n'}}\n{%- endif %}\n{%- for message in messages %}\n    {%- if message['role'] == 'system' %}\n{{ message['content'] }}\n    {%- else %}\n        {%- if message['role'] == 'user' %}\n{{'### Instruction:\\n' + message['content'] + '\\n'}}\n        {%- else %}\n{{'### Response:\\n' + message['content'] + '\\n<|EOT|>\\n'}}\n        {%- endif %}\n    {%- endif %}\n{%- endfor %}\n{{'### Response:\\n'}}\n"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messages
            ] as [String: Any]
        )
        let target =
            "You are an AI programming assistant, utilizing the Deepseek Coder model, developed by Deepseek Company, and you only answer questions related to computer science. For politically sensitive questions, security and privacy issues, and other non-computer science questions, you will refuse to answer.\n### Instruction:\nHello, how are you?\n### Response:\nI'm doing great. How can I help you today?\n<|EOT|>\n### Instruction:\nI'd like to show off how chat templating works!\n### Response:\n"

        if target != result {
            print("::: testTheBlokedeepseekCoder33BInstructAWQ failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testEriczzzFalconRw1bChat() throws {
        let chatTemplate =
            "{% for message in messages %}{% if loop.index > 1 and loop.previtem['role'] != 'assistant' %}{{ ' ' }}{% endif %}{% if message['role'] == 'system' %}{{ '[SYS] ' + message['content'].strip() }}{% elif message['role'] == 'user' %}{{ '[INST] ' + message['content'].strip() }}{% elif message['role'] == 'assistant' %}{{ '[RESP] '  + message['content'] + eos_token }}{% endif %}{% endfor %}{% if add_generation_prompt %}{{ ' [RESP] ' }}{% endif %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messages, "eos_token": "<|endoftext|>",
            ] as [String: Any]
        )
        let target =
            "[INST] Hello, how are you? [RESP] I'm doing great. How can I help you today?<|endoftext|>[INST] I'd like to show off how chat templating works!"

        if target != result {
            print("::: testEriczzzFalconRw1bChat failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testAbacusaiSmaug34BV0_1() throws {
        let chatTemplate =
            "{%- for idx in range(0, messages|length) -%}\n{%- if messages[idx]['role'] == 'user' -%}\n{%- if idx > 1 -%}\n{{- bos_token + '[INST] ' + messages[idx]['content'] + ' [/INST]' -}}\n{%- else -%}\n{{- messages[idx]['content'] + ' [/INST]' -}}\n{%- endif -%}\n{% elif messages[idx]['role'] == 'system' %}\n{{- '[INST] <<SYS>>\\n' + messages[idx]['content'] + '\\n<</SYS>>\\n\\n' -}}\n{%- elif messages[idx]['role'] == 'assistant' -%}\n{{- ' '  + messages[idx]['content'] + ' ' + eos_token -}}\n{% endif %}\n{% endfor %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messages, "bos_token": "<s>", "eos_token": "</s>",
            ] as [String: Any]
        )
        let target =
            "Hello, how are you? [/INST] I'm doing great. How can I help you today? </s><s>[INST] I'd like to show off how chat templating works! [/INST]"

        if target != result {
            print("::: testAbacusaiSmaug34BV0_1 failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testMaywellSynatraMixtral8x7B() throws {
        let chatTemplate =
            "Below is an instruction that describes a task. Write a response that appropriately completes the request.\n\n{% for message in messages %}{% if message['role'] == 'user' %}### Instruction:\n{{ message['content']|trim -}}{% if not loop.last %}{% endif %}\n{% elif message['role'] == 'assistant' %}### Response:\n{{ message['content']|trim -}}{% if not loop.last %}{% endif %}\n{% elif message['role'] == 'system' %}{{ message['content']|trim -}}{% if not loop.last %}{% endif %}\n{% endif %}\n{% endfor %}\n{% if add_generation_prompt and messages[-1]['role'] != 'assistant' %}\n### Response:\n{% endif %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messages
            ] as [String: Any]
        )
        let target =
            "Below is an instruction that describes a task. Write a response that appropriately completes the request.\n\n### Instruction:\nHello, how are you?### Response:\nI'm doing great. How can I help you today?### Instruction:\nI'd like to show off how chat templating works!"

        if target != result {
            print("::: testMaywellSynatraMixtral8x7B failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testDeepseekAiDeepseekCoder33bInstruct() throws {
        let chatTemplate =
            "{% if not add_generation_prompt is defined %}\n{% set add_generation_prompt = false %}\n{% endif %}\n{%- set ns = namespace(found=false) -%}\n{%- for message in messages -%}\n    {%- if message['role'] == 'system' -%}\n        {%- set ns.found = true -%}\n    {%- endif -%}\n{%- endfor -%}\n{{bos_token}}{%- if not ns.found -%}\n{{'You are an AI programming assistant, utilizing the Deepseek Coder model, developed by Deepseek Company, and you only answer questions related to computer science. For politically sensitive questions, security and privacy issues, and other non-computer science questions, you will refuse to answer\\n'}}\n{%- endif %}\n{%- for message in messages %}\n    {%- if message['role'] == 'system' %}\n{{ message['content'] }}\n    {%- else %}\n        {%- if message['role'] == 'user' %}\n{{'### Instruction:\\n' + message['content'] + '\\n'}}\n        {%- else %}\n{{'### Response:\\n' + message['content'] + '\\n<|EOT|>\\n'}}\n        {%- endif %}\n    {%- endif %}\n{%- endfor %}\n{% if add_generation_prompt %}\n{{'### Response:'}}\n{% endif %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messages, "bos_token": "<｜begin of sentence｜>", "eos_token": "<|EOT|>",
            ] as [String: Any]
        )
        let target =
            "<｜begin of sentence｜>You are an AI programming assistant, utilizing the Deepseek Coder model, developed by Deepseek Company, and you only answer questions related to computer science. For politically sensitive questions, security and privacy issues, and other non-computer science questions, you will refuse to answer\n### Instruction:\nHello, how are you?\n### Response:\nI'm doing great. How can I help you today?\n<|EOT|>\n### Instruction:\nI'd like to show off how chat templating works!\n"

        if target != result {
            print("::: testDeepseekAiDeepseekCoder33bInstruct failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testMaywellSynatraMixtral8x7B_2() throws {
        let chatTemplate =
            "Below is an instruction that describes a task. Write a response that appropriately completes the request.\n\n{% for message in messages %}{% if message['role'] == 'user' %}### Instruction:\n{{ message['content']|trim -}}{% if not loop.last %}{% endif %}\n{% elif message['role'] == 'assistant' %}### Response:\n{{ message['content']|trim -}}{% if not loop.last %}{% endif %}\n{% elif message['role'] == 'system' %}{{ message['content']|trim -}}{% if not loop.last %}{% endif %}\n{% endif %}\n{% endfor %}\n{% if add_generation_prompt and messages[-1]['role'] != 'assistant' %}\n### Response:\n{% endif %}"
        let template = try Template(chatTemplate)
        let result = try template.render(
            [
                "messages": messagesWithSystemPrompt
            ] as [String: Any]
        )
        let target =
            "Below is an instruction that describes a task. Write a response that appropriately completes the request.\n\nYou are a friendly chatbot who always responds in the style of a pirate### Instruction:\nHello, how are you?### Response:\nI'm doing great. How can I help you today?### Instruction:\nI'd like to show off how chat templating works!"

        if target != result {
            print("::: testMaywellSynatraMixtral8x7B_2 failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }

    func testMistralNemoInstruct2407() throws {
        let chatTemplate =
            "{%- if messages[0][\"role\"] == \"system\" %}\n    {%- set system_message = messages[0][\"content\"] %}\n    {%- set loop_messages = messages[1:] %}\n{%- else %}\n    {%- set loop_messages = messages %}\n{%- endif %}\n{%- if not tools is defined %}\n    {%- set tools = none %}\n{%- endif %}\n{%- set user_messages = loop_messages | selectattr(\"role\", \"equalto\", \"user\") | list %}\n\n{%- for message in loop_messages | rejectattr(\"role\", \"equalto\", \"tool\") | rejectattr(\"role\", \"equalto\", \"tool_results\") | selectattr(\"tool_calls\", \"undefined\") %}\n    {%- if (message[\"role\"] == \"user\") != (loop.index0 % 2 == 0) %}\n        {{- raise_exception(\"After the optional system message, conversation roles must alternate user/assistant/user/assistant/...\") }}\n    {%- endif %}\n{%- endfor %}\n\n{{- bos_token }}\n{%- for message in loop_messages %}\n    {%- if message[\"role\"] == \"user\" %}\n        {%- if tools is not none and (message == user_messages[-1]) %}\n            {{- \"[AVAILABLE_TOOLS][\" }}\n            {%- for tool in tools %}\n        {%- set tool = tool.function %}\n        {{- '{\"type\": \"function\", \"function\": {' }}\n        {%- for key, val in tool.items() if key != \"return\" %}\n            {%- if val is string %}\n            {{- '\"' + key + '\": \"' + val + '\"' }}\n            {%- else %}\n            {{- '\"' + key + '\": ' + val|tojson }}\n            {%- endif %}\n            {%- if not loop.last %}\n            {{- \", \" }}\n            {%- endif %}\n        {%- endfor %}\n        {{- \"}}\" }}\n                {%- if not loop.last %}\n                    {{- \", \" }}\n                {%- else %}\n                    {{- \"]\" }}\n                {%- endif %}\n            {%- endfor %}\n            {{- \"[/AVAILABLE_TOOLS]\" }}\n            {%- endif %}\n        {%- if loop.last and system_message is defined %}\n            {{- \"[INST]\" + system_message + \"\\n\\n\" + message[\"content\"] + \"[/INST]\" }}\n        {%- else %}\n            {{- \"[INST]\" + message[\"content\"] + \"[/INST]\" }}\n        {%- endif %}\n    {%- elif message[\"role\"] == \"tool_calls\" or message.tool_calls is defined %}\n        {%- if message.tool_calls is defined %}\n            {%- set tool_calls = message.tool_calls %}\n        {%- else %}\n            {%- set tool_calls = message.content %}\n        {%- endif %}\n        {{- \"[TOOL_CALLS][\" }}\n        {%- for tool_call in tool_calls %}\n            {%- set out = tool_call.function|tojson %}\n            {{- out[:-1] }}\n            {%- if not tool_call.id is defined or tool_call.id|length != 9 %}\n                {{- raise_exception(\"Tool call IDs should be alphanumeric strings with length 9!\") }}\n            {%- endif %}\n            {{- ', \"id\": \"' + tool_call.id + '\"}' }}\n            {%- if not loop.last %}\n                {{- \", \" }}\n            {%- else %}\n                {{- \"]\" + eos_token }}\n            {%- endif %}\n        {%- endfor %}\n    {%- elif message[\"role\"] == \"assistant\" %}\n        {{- message[\"content\"] + eos_token}}\n    {%- elif message[\"role\"] == \"tool_results\" or message[\"role\"] == \"tool\" %}\n        {%- if message.content is defined and message.content.content is defined %}\n            {%- set content = message.content.content %}\n        {%- else %}\n            {%- set content = message.content %}\n        {%- endif %}\n        {{- '[TOOL_RESULTS]{\"content\": ' + content|string + \", \" }}\n        {%- if not message.tool_call_id is defined or message.tool_call_id|length != 9 %}\n            {{- raise_exception(\"Tool call IDs should be alphanumeric strings with length 9!\") }}\n        {%- endif %}\n        {{- '\"call_id\": \"' + message.tool_call_id + '\"}[/TOOL_RESULTS]' }}\n    {%- else %}\n        {{- raise_exception(\"Only user and assistant roles are supported, with the exception of an initial optional system message!\") }}\n    {%- endif %}\n{%- endfor %}\n"
        let template = try Template(chatTemplate)
        let result = try template.render([
            "messages": messages,
            "bos_token": "<s>",
            "eos_token": "</s>",
        ])
        let target =
            "<s>[INST]Hello, how are you?[/INST]I'm doing great. How can I help you today?</s>[INST]I'd like to show off how chat templating works![/INST]"

        XCTAssertEqual(result, target)
    }

    func testQwen2VLTextOnly() throws {
        let qwen2VLChatTemplate =
            "{% set image_count = namespace(value=0) %}{% set video_count = namespace(value=0) %}{% for message in messages %}{% if loop.first and message['role'] != 'system' %}<|im_start|>system\nYou are a helpful assistant.<|im_end|>\n{% endif %}<|im_start|>{{ message['role'] }}\n{% if message['content'] is string %}{{ message['content'] }}<|im_end|>\n{% else %}{% for content in message['content'] %}{% if content['type'] == 'image' or 'image' in content or 'image_url' in content %}{% set image_count.value = image_count.value + 1 %}{% if add_vision_id %}Picture {{ image_count.value }}: {% endif %}<|vision_start|><|image_pad|><|vision_end|>{% elif content['type'] == 'video' or 'video' in content %}{% set video_count.value = video_count.value + 1 %}{% if add_vision_id %}Video {{ video_count.value }}: {% endif %}<|vision_start|><|video_pad|><|vision_end|>{% elif 'text' in content %}{{ content['text'] }}{% endif %}{% endfor %}<|im_end|>\n{% endif %}{% endfor %}{% if add_generation_prompt %}<|im_start|>assistant\n{% endif %}"
        let template = try Template(qwen2VLChatTemplate)
        let result = try template.render([
            "messages": messages,
            "add_generation_prompt": true,
        ])
        let target = """
            <|im_start|>system
            You are a helpful assistant.<|im_end|>
            <|im_start|>user
            Hello, how are you?<|im_end|>
            <|im_start|>assistant
            I'm doing great. How can I help you today?<|im_end|>
            <|im_start|>user
            I'd like to show off how chat templating works!<|im_end|>
            <|im_start|>assistant

            """

        if target != result {
            print("::: testQwen2VLTextOnly failed.")
            print("::: target:")
            print(target)
            print("::: result:")
            print(result)
        }
        XCTAssertEqual(result, target)
    }
}
